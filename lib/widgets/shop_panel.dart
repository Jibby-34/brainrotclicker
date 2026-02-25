import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_data.dart';
import 'building_card.dart';
import 'upgrade_card.dart';

class ShopPanel extends StatefulWidget {
  const ShopPanel({super.key});

  @override
  State<ShopPanel> createState() => _ShopPanelState();
}

class _ShopPanelState extends State<ShopPanel> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0A2E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x50000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          // Custom pill tab toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Colors.white.withValues(alpha: 0.07),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  _PillTab(
                    label: '🧑 Characters',
                    selected: _selected == 0,
                    onTap: () => setState(() => _selected = 0),
                  ),
                  _PillTab(
                    label: '⚡ Upgrades',
                    selected: _selected == 1,
                    onTap: () => setState(() => _selected = 1),
                  ),
                ],
              ),
            ),
          ),
          // Tab content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _selected == 0
                  ? ListView(
                      key: const ValueKey('chars'),
                      padding: const EdgeInsets.only(bottom: 12),
                      children:
                          kCharacters.map((c) => BuildingCard(character: c)).toList(),
                    )
                  : ListView(
                      key: const ValueKey('upgrades'),
                      padding: const EdgeInsets.only(bottom: 12),
                      children:
                          kClickUpgrades.map((u) => UpgradeCard(upgrade: u)).toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: selected ? const Color(0xFFB06EFF) : Colors.transparent,
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x60B06EFF),
                      blurRadius: 0,
                      offset: Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.bangers(
              fontSize: 15,
              letterSpacing: 1,
              color: selected ? Colors.white : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }
}
