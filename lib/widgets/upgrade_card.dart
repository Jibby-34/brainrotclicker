import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_data.dart';
import '../models/game_state.dart';

class UpgradeCard extends StatelessWidget {
  final ClickUpgrade upgrade;

  const UpgradeCard({super.key, required this.upgrade});

  static const _pink = Color(0xFFFF4D9E);
  static const _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final purchased = gs.isUpgradePurchased(upgrade.id);
    final affordable = gs.canAfford(upgrade.cost);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: purchased ? 0.38 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: purchased
              ? const Color(0xFF160D3A)
              : affordable
                  ? _pink.withValues(alpha: 0.2)
                  : const Color(0xFF1C0E48),
          border: Border.all(
            color: purchased
                ? Colors.white.withValues(alpha: 0.08)
                : affordable
                    ? _pink
                    : Colors.white.withValues(alpha: 0.12),
            width: 2.5,
          ),
          boxShadow: (!purchased && affordable)
              ? [
                  BoxShadow(
                    color: _pink.withValues(alpha: 0.45),
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: (!purchased && affordable)
                ? () => gs.buyUpgrade(upgrade)
                : null,
            splashColor: _pink.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: purchased
                          ? Colors.white.withValues(alpha: 0.05)
                          : affordable
                              ? _pink.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: purchased
                            ? Colors.white12
                            : affordable
                                ? _pink.withValues(alpha: 0.65)
                                : Colors.white.withValues(alpha: 0.1),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        purchased ? '✓' : '⚡',
                        style: TextStyle(
                          fontSize: purchased ? 20 : 24,
                          color: purchased ? Colors.white30 : _pink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          upgrade.name,
                          style: GoogleFonts.bangers(
                            fontSize: 17,
                            color: purchased
                                ? Colors.white30
                                : affordable
                                    ? _pink
                                    : Colors.white38,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          purchased ? 'Already purchased!' : upgrade.description,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cost pill
                  if (!purchased)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: affordable
                            ? _gold.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: affordable
                              ? _gold.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🧠', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 3),
                          Text(
                            gs.formatNumber(upgrade.cost),
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: affordable ? _gold : Colors.white30,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
