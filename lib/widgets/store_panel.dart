import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../services/ad_service.dart';
import '../services/iap_service.dart';

class StorePanel extends StatelessWidget {
  const StorePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      children: const [
        _WatchAdCard(),
        SizedBox(height: 16),
        _SectionHeader(icon: '🧠', label: 'BRAIN PACKS'),
        SizedBox(height: 8),
        _BrainPackCard(
          productId: IAPService.brainsSmall,
          emoji: '🧠',
          title: 'Starter Pack',
          subtitle: '+1,000 Brains',
          gradientColors: [Color(0xFF4ECDC4), Color(0xFF2EAE95)],
          shadowColor: Color(0x554ECDC4),
        ),
        SizedBox(height: 8),
        _BrainPackCard(
          productId: IAPService.brainsMedium,
          emoji: '🧠🧠',
          title: 'Brain Boost',
          subtitle: '+10,000 Brains',
          gradientColors: [Color(0xFFFF9F43), Color(0xFFFF6B35)],
          shadowColor: Color(0x55FF9F43),
        ),
        SizedBox(height: 8),
        _BrainPackCard(
          productId: IAPService.brainsLarge,
          emoji: '🧠🧠🧠',
          title: 'Mega Brain',
          subtitle: '+100,000 Brains',
          gradientColors: [Color(0xFFFF6B9D), Color(0xFFCC2D77)],
          shadowColor: Color(0x55FF6B9D),
        ),
        SizedBox(height: 16),
        _SectionHeader(icon: '⚡', label: 'PREMIUM BOOSTS'),
        SizedBox(height: 8),
        _UpgradeCard(
          productId: IAPService.upgradeSpeedDemon,
          icon: '⚡',
          title: 'Speed Demon',
          subtitle: 'Permanently doubles all CPS',
          gradientColors: [Color(0xFFB06EFF), Color(0xFF7B3FCC)],
          shadowColor: Color(0x55B06EFF),
        ),
        SizedBox(height: 8),
        _UpgradeCard(
          productId: IAPService.upgradeBrainOverload,
          icon: '🔥',
          title: 'Brain Overload',
          subtitle: 'Permanently 5× tap power',
          gradientColors: [Color(0xFFFF6B6B), Color(0xFFCC2B2B)],
          shadowColor: Color(0x55FF6B6B),
        ),
        SizedBox(height: 12),
        _RestoreButton(),
      ],
    );
  }
}

// ── Watch Ad Card ─────────────────────────────────────────────────────────────

class _WatchAdCard extends StatelessWidget {
  const _WatchAdCard();

  @override
  Widget build(BuildContext context) {
    final adService = context.watch<AdService>();
    final gameState = context.watch<GameState>();

    final isReady = adService.isAdReady;
    final isLoading = adService.isLoading;
    final reward = AdService.computeReward(gameState.cps);

    return GestureDetector(
      onTap: isReady
          ? () => _watchAd(context, adService, gameState)
          : isLoading
              ? null
              : () => adService.loadRewardedAd(),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isReady
                ? const [Color(0xFFFFE66D), Color(0xFFFF9F43)]
                : [
                    const Color(0xFF2A2A4A),
                    const Color(0xFF1A1A3A),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: isReady
                  ? const Color(0x88FFE66D)
                  : const Color(0x22000000),
              blurRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
          border: isReady
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1.5,
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isReady
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.07),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      )
                    : Text(
                        isReady ? '▶' : '📡',
                        style: TextStyle(
                          fontSize: isReady ? 20 : 22,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isReady
                        ? 'WATCH A FREE AD'
                        : isLoading
                            ? 'LOADING AD…'
                            : 'AD UNAVAILABLE',
                    style: GoogleFonts.bangers(
                      fontSize: 17,
                      letterSpacing: 1.5,
                      color: isReady ? const Color(0xFF3D1A00) : Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isReady
                        ? 'Get ${gameState.formatNumber(reward.toDouble())} 🧠 for free!'
                        : isLoading
                            ? 'Finding an ad for you…'
                            : 'Tap to retry loading',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isReady
                          ? const Color(0xFF7A3D00).withValues(alpha: 0.85)
                          : Colors.white30,
                    ),
                  ),
                ],
              ),
            ),
            if (isReady)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF3D1A00).withValues(alpha: 0.2),
                ),
                child: Text(
                  'FREE',
                  style: GoogleFonts.bangers(
                    fontSize: 14,
                    letterSpacing: 1,
                    color: const Color(0xFF3D1A00),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _watchAd(
    BuildContext context,
    AdService adService,
    GameState gameState,
  ) {
    adService.showRewardedAd(
      onRewarded: () {
        final earnedReward = AdService.computeReward(gameState.cps);
        gameState.addBrains(earnedReward.toDouble());
        if (context.mounted) {
          _showToast(
              context,
              '+${gameState.formatNumber(earnedReward.toDouble())} 🧠 added!',
              Colors.amber);
        }
      },
      onFailed: () {
        if (context.mounted) {
          _showToast(context, 'Ad not available. Try again later.',
              Colors.redAccent);
        }
      },
    );
  }
}

// ── Brain Pack Card ───────────────────────────────────────────────────────────

class _BrainPackCard extends StatelessWidget {
  final String productId;
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color shadowColor;

  const _BrainPackCard({
    required this.productId,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IAPService>();
    final product = iap.products[productId];
    final isAvailable = iap.available;

    return _StoreCard(
      gradientColors: gradientColors,
      shadowColor: shadowColor,
      enabled: isAvailable && product != null,
      onTap: () => _buy(context, iap),
      leading: Text(emoji, style: const TextStyle(fontSize: 24)),
      title: title,
      subtitle: subtitle,
      trailing: _PriceTag(
        label: product?.price ?? (iap.loading ? '…' : 'N/A'),
        colors: gradientColors,
      ),
    );
  }

  void _buy(BuildContext context, IAPService iap) {
    iap.buy(productId).then((_) {}).catchError((_) {
      if (context.mounted) {
        _showToast(context, 'Purchase failed. Try again.', Colors.redAccent);
      }
    });
  }
}

// ── Upgrade Card ──────────────────────────────────────────────────────────────

class _UpgradeCard extends StatelessWidget {
  final String productId;
  final String icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color shadowColor;

  const _UpgradeCard({
    required this.productId,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IAPService>();
    final gameState = context.watch<GameState>();
    final product = iap.products[productId];
    final isPurchased = gameState.isIapUpgradePurchased(productId);
    final isAvailable = iap.available;

    return _StoreCard(
      gradientColors:
          isPurchased ? [const Color(0xFF2A2A4A), const Color(0xFF1E1E3A)] : gradientColors,
      shadowColor: isPurchased ? Colors.transparent : shadowColor,
      enabled: !isPurchased && isAvailable && product != null,
      onTap: isPurchased ? null : () => _buy(context, iap),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPurchased
              ? Colors.white.withValues(alpha: 0.07)
              : gradientColors.first.withValues(alpha: 0.2),
        ),
        child: Center(
          child: Text(
            isPurchased ? '✓' : icon,
            style: TextStyle(
              fontSize: isPurchased ? 18 : 20,
              color: isPurchased ? Colors.greenAccent : null,
            ),
          ),
        ),
      ),
      title: title,
      subtitle: isPurchased ? 'Already owned' : subtitle,
      trailing: isPurchased
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.greenAccent.withValues(alpha: 0.15),
                border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.4),
                    width: 1.5),
              ),
              child: Text(
                'OWNED',
                style: GoogleFonts.bangers(
                  fontSize: 13,
                  letterSpacing: 1,
                  color: Colors.greenAccent,
                ),
              ),
            )
          : _PriceTag(
              label: product?.price ?? (iap.loading ? '…' : 'N/A'),
              colors: gradientColors,
            ),
    );
  }

  void _buy(BuildContext context, IAPService iap) {
    iap.buy(productId).then((_) {}).catchError((_) {
      if (context.mounted) {
        _showToast(context, 'Purchase failed. Try again.', Colors.redAccent);
      }
    });
  }
}

// ── Shared store card layout ──────────────────────────────────────────────────

class _StoreCard extends StatelessWidget {
  final List<Color> gradientColors;
  final Color shadowColor;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _StoreCard({
    required this.gradientColors,
    required this.shadowColor,
    required this.enabled,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradientColors.first.withValues(alpha: 0.15),
                gradientColors.last.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: gradientColors.first.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.bangers(
                        fontSize: 16,
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Price tag ─────────────────────────────────────────────────────────────────

class _PriceTag extends StatelessWidget {
  final String label;
  final List<Color> colors;

  const _PriceTag({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.bangers(
          fontSize: 14,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.bangers(
            fontSize: 13,
            letterSpacing: 2,
            color: Colors.white38,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}

// ── Restore purchases button ──────────────────────────────────────────────────

class _RestoreButton extends StatelessWidget {
  const _RestoreButton();

  @override
  Widget build(BuildContext context) {
    final iap = context.read<IAPService>();

    return Center(
      child: GestureDetector(
        onTap: () {
          iap.restorePurchases();
          _showToast(context, 'Restoring purchases…', Colors.white54);
        },
        child: Text(
          'Restore Purchases',
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white30,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white30,
          ),
        ),
      ),
    );
  }
}

// ── Toast helper ──────────────────────────────────────────────────────────────

void _showToast(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFF1A1A3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      duration: const Duration(seconds: 2),
    ),
  );
}
