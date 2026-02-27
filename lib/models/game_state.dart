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
  Timer? _ticker;
  Timer? _saveTicker;

  static const _keyTotalClicks = 'totalClicks';
  static const _keyClickPower = 'clickPower';
  static const _keyOwned = 'owned';
  static const _keyPurchasedUpgrades = 'purchasedUpgrades';

  GameState._({
    double totalClicks = 0,
    double clickPower = 1,
    Map<String, int>? owned,
    Set<String>? purchasedUpgrades,
  })  : _totalClicks = totalClicks,
        _clickPower = clickPower,
        _owned = owned ?? {},
        _purchasedUpgrades = purchasedUpgrades ?? {} {
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

    return GameState._(
      totalClicks: totalClicks,
      clickPower: clickPower,
      owned: owned,
      purchasedUpgrades: purchasedUpgrades,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTotalClicks, _totalClicks);
    await prefs.setDouble(_keyClickPower, _clickPower);
    await prefs.setString(_keyOwned, jsonEncode(_owned));
    await prefs.setStringList(
        _keyPurchasedUpgrades, _purchasedUpgrades.toList());
  }

  // ── Getters ──────────────────────────────────────────────────────────────────

  double get totalClicks => _totalClicks;
  double get clickPower => _clickPower;

  double get cps {
    double total = 0;
    for (final c in kCharacters) {
      total += (_owned[c.id] ?? 0) * c.cpsPerUnit;
    }
    return total;
  }

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
