import 'dart:async';
import 'package:flutter/foundation.dart';
import 'game_data.dart';

class GameState extends ChangeNotifier {
  double _totalClicks = 0;
  double _clickPower = 1;
  final Map<String, int> _owned = {};
  final Set<String> _purchasedUpgrades = {};
  Timer? _ticker;

  GameState() {
    for (final c in kCharacters) {
      _owned[c.id] = 0;
    }
    _ticker = Timer.periodic(const Duration(milliseconds: 100), _onTick);
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
    notifyListeners();
  }

  void buyUpgrade(ClickUpgrade upgrade) {
    if (_purchasedUpgrades.contains(upgrade.id)) return;
    if (!canAfford(upgrade.cost)) return;
    _totalClicks -= upgrade.cost;
    _purchasedUpgrades.add(upgrade.id);
    _clickPower *= upgrade.multiplier;
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
