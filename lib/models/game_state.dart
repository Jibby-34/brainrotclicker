import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_data.dart';

class GameState extends ChangeNotifier {
  double _totalClicks;
  double _clickPower;
  final Map<String, int> _owned;
  final Set<String> _purchasedUpgrades;
  final Set<String> _iapUpgrades;
  Timer? _ticker;
  Timer? _saveTicker;

  /// Brains earned while the app was closed, waiting to be claimed.
  double _pendingOfflineEarnings;

  /// How many seconds the player was offline (for display purposes).
  double _offlineSeconds;

  static const _keyTotalClicks = 'totalClicks';
  static const _keyClickPower = 'clickPower';
  static const _keyOwned = 'owned';
  static const _keyPurchasedUpgrades = 'purchasedUpgrades';
  static const _keyIapUpgrades = 'iapUpgrades';
  static const _keyLastSeen = 'lastSeen';

  /// Offline rate: 50 % of normal CPS.
  static const double offlineRateMultiplier = 0.5;

  /// Maximum offline time credited (8 hours).
  static const double _maxOfflineSeconds = 8 * 3600;

  // IAP upgrade product IDs (mirrored from IAPService to avoid circular import)
  static const iapSpeedDemon = 'upgrade_speed_demon';
  static const iapBrainOverload = 'upgrade_brain_overload';

  GameState._({
    double totalClicks = 0,
    double clickPower = 1,
    Map<String, int>? owned,
    Set<String>? purchasedUpgrades,
    Set<String>? iapUpgrades,
    double pendingOfflineEarnings = 0,
    double offlineSeconds = 0,
  })  : _totalClicks = totalClicks,
        _clickPower = clickPower,
        _owned = owned ?? {},
        _purchasedUpgrades = purchasedUpgrades ?? {},
        _iapUpgrades = iapUpgrades ?? {},
        _pendingOfflineEarnings = pendingOfflineEarnings,
        _offlineSeconds = offlineSeconds {
    for (final c in kCharacters) {
      _owned.putIfAbsent(c.id, () => 0);
    }
    _ticker = Timer.periodic(const Duration(milliseconds: 100), _onTick);
    // Autosave every 5 seconds to capture passive income & taps
    _saveTicker = Timer.periodic(const Duration(seconds: 5), (_) => _save());
  }

  static Future<GameState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final totalClicks = prefs.getDouble(_keyTotalClicks) ?? 0;
    final clickPower = prefs.getDouble(_keyClickPower) ?? 1;

    Map<String, int> owned = {};
    final ownedJson = prefs.getString(_keyOwned);
    if (ownedJson != null) {
      final decoded = jsonDecode(ownedJson) as Map<String, dynamic>;
      owned = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    }

    Set<String> purchasedUpgrades = {};
    final upgradesList = prefs.getStringList(_keyPurchasedUpgrades);
    if (upgradesList != null) {
      purchasedUpgrades = upgradesList.toSet();
    }

    Set<String> iapUpgrades = {};
    final iapList = prefs.getStringList(_keyIapUpgrades);
    if (iapList != null) {
      iapUpgrades = iapList.toSet();
    }

    // ── Offline earnings calculation ─────────────────────────────────────────
    double pendingOffline = 0;
    double offlineSeconds = 0;
    final lastSeenMs = prefs.getInt(_keyLastSeen);
    if (lastSeenMs != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      offlineSeconds =
          ((now - lastSeenMs) / 1000).clamp(0, _maxOfflineSeconds).toDouble();

      // Compute CPS from the saved building counts (mirrors the cps getter).
      double savedCps = 0;
      for (final c in kCharacters) {
        savedCps += (owned[c.id] ?? 0) * c.cpsPerUnit;
      }
      if (iapUpgrades.contains(iapSpeedDemon)) savedCps *= 2;

      // Only show the dialog if the player has been gone > 1 min and has CPS.
      if (savedCps > 0 && offlineSeconds >= 60) {
        pendingOffline = savedCps * offlineSeconds * offlineRateMultiplier;
      }
    }

    final state = GameState._(
      totalClicks: totalClicks,
      clickPower: clickPower,
      owned: owned,
      purchasedUpgrades: purchasedUpgrades,
      iapUpgrades: iapUpgrades,
      pendingOfflineEarnings: pendingOffline,
      offlineSeconds: offlineSeconds,
    );

    // Write lastSeen immediately so subsequent relaunches measure from now.
    await state._save();
    return state;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTotalClicks, _totalClicks);
    await prefs.setDouble(_keyClickPower, _clickPower);
    await prefs.setString(_keyOwned, jsonEncode(_owned));
    await prefs.setStringList(
        _keyPurchasedUpgrades, _purchasedUpgrades.toList());
    await prefs.setStringList(_keyIapUpgrades, _iapUpgrades.toList());
    await prefs.setInt(
        _keyLastSeen, DateTime.now().millisecondsSinceEpoch);
  }

  // ── Getters ──────────────────────────────────────────────────────────────────

  double get totalClicks => _totalClicks;
  double get clickPower => _clickPower;
  double get pendingOfflineEarnings => _pendingOfflineEarnings;
  double get offlineSeconds => _offlineSeconds;

  double get cps {
    double total = 0;
    for (final c in kCharacters) {
      total += (_owned[c.id] ?? 0) * c.cpsPerUnit;
    }
    if (_iapUpgrades.contains(iapSpeedDemon)) total *= 2;
    return total;
  }

  bool isIapUpgradePurchased(String productId) =>
      _iapUpgrades.contains(productId);

  int owned(String characterId) => _owned[characterId] ?? 0;
  bool isUpgradePurchased(String upgradeId) =>
      _purchasedUpgrades.contains(upgradeId);

  /// Returns the highest-tier character the player owns ≥1 of,
  /// falling back to the first character if none owned yet.
  CharacterBuilding get activeCharacter {
    CharacterBuilding? best;
    for (final c in kCharacters) {
      if ((_owned[c.id] ?? 0) > 0) best = c;
    }
    return best ?? kCharacters.first;
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  void tap() {
    _totalClicks += _clickPower;
    notifyListeners();
  }

  /// Awards the pending offline brains and clears the pending amount.
  void claimOfflineEarnings() {
    if (_pendingOfflineEarnings <= 0) return;
    _totalClicks += _pendingOfflineEarnings;
    _pendingOfflineEarnings = 0;
    _offlineSeconds = 0;
    _save();
    notifyListeners();
  }

  bool canAfford(double cost) => _totalClicks >= cost;

  void buyBuilding(CharacterBuilding character) {
    final cost = character.costForNext(owned(character.id));
    if (!canAfford(cost)) return;
    _totalClicks -= cost;
    _owned[character.id] = (_owned[character.id] ?? 0) + 1;
    _save();
    notifyListeners();
  }

  void buyUpgrade(ClickUpgrade upgrade) {
    if (_purchasedUpgrades.contains(upgrade.id)) return;
    if (!canAfford(upgrade.cost)) return;
    _totalClicks -= upgrade.cost;
    _purchasedUpgrades.add(upgrade.id);
    _clickPower *= upgrade.multiplier;
    _save();
    notifyListeners();
  }

  void addBrains(double amount) {
    _totalClicks += amount;
    _save();
    notifyListeners();
  }

  void applyIapUpgrade(String productId) {
    if (_iapUpgrades.contains(productId)) return;
    _iapUpgrades.add(productId);
    if (productId == iapBrainOverload) {
      _clickPower *= 5;
    }
    _save();
    notifyListeners();
  }

  void handleIapPurchase(String productId) {
    switch (productId) {
      case 'brains_small':
        addBrains(1000);
      case 'brains_medium':
        addBrains(10000);
      case 'brains_large':
        addBrains(100000);
      case iapSpeedDemon:
      case iapBrainOverload:
        applyIapUpgrade(productId);
    }
  }

  // ── Internal ─────────────────────────────────────────────────────────────────

  void _onTick(Timer _) {
    if (cps == 0) return;
    _totalClicks += cps / 10;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _saveTicker?.cancel();
    _save();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String formatNumber(double n) {
    if (n >= 1e12) return '${(n / 1e12).toStringAsFixed(1)}T';
    if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}B';
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}
