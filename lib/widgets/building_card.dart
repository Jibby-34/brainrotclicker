import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_data.dart';
import '../models/game_state.dart';

class BuildingCard extends StatelessWidget {
  final CharacterBuilding character;

  const BuildingCard({super.key, required this.character});

  static const _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final ownedCount = gs.owned(character.id);
    final cost = character.costForNext(ownedCount);
    final affordable = gs.canAfford(cost);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: affordable
            ? character.color.withValues(alpha: 0.22)
            : const Color(0xFF1C0E48),
        border: Border.all(
          color: affordable
              ? character.color
              : Colors.white.withValues(alpha: 0.12),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: affordable
                ? character.color.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.4),
            offset: const Offset(0, 4),
            blurRadius: affordable ? 0 : 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: affordable ? () => gs.buyBuilding(character) : null,
          splashColor: character.color.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Character thumbnail
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: character.color.withValues(alpha: 0.2),
                    border: Border.all(
                      color: character.color.withValues(alpha: 0.55),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Image.asset(
                      character.assetPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + CPS info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        character.name,
                        style: GoogleFonts.bangers(
                          fontSize: 17,
                          color: affordable ? character.color : Colors.white38,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '+${character.cpsPerUnit} brains/sec',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Cost + owned
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _CostPill(
                      cost: gs.formatNumber(cost),
                      affordable: affordable,
                    ),
                    const SizedBox(height: 5),
                    _CountBadge(
                      count: ownedCount,
                      color: character.color,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CostPill extends StatelessWidget {
  final String cost;
  final bool affordable;
  static const _gold = Color(0xFFFFD700);

  const _CostPill({required this.cost, required this.affordable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            cost,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: affordable ? _gold : Colors.white30,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: count > 0
            ? color.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: count > 0
              ? color.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: Text(
        count > 0 ? '× $count' : '× 0',
        style: GoogleFonts.bangers(
          fontSize: 14,
          color: count > 0 ? color : Colors.white24,
        ),
      ),
    );
  }
}
