import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/presentation/utils/page_transitions.dart';
import '../../domain/entities/subscription_status.dart';
import '../viewmodels/premium_viewmodel.dart';
import '../views/plans_view.dart';

/// Banner de Premium que aparece en el Home.
///
/// Si el usuario es free: muestra un CTA atractivo para probar premium.
/// Si es premium: muestra un badge discreto con los días restantes.
class PremiumHomeBanner extends StatefulWidget {
  const PremiumHomeBanner({super.key});

  @override
  State<PremiumHomeBanner> createState() => _PremiumHomeBannerState();
}

class _PremiumHomeBannerState extends State<PremiumHomeBanner> {
  late final PremiumViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = sl<PremiumViewModel>();
    _vm.load();
    _vm.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    super.dispose();
  }

  void _openPlans() {
    Navigator.push(context, fadeSlideRoute(const PlansView()));
  }

  @override
  Widget build(BuildContext context) {
    final status = _vm.status;

    if (status.isPremium) {
      return _PremiumActiveBadge(status: status, onTap: _openPlans);
    }

    return _UpgradeBanner(
      canTrial: status.canStartTrial,
      onTap: _openPlans,
    );
  }
}

/// Banner CTA para usuarios free.
class _UpgradeBanner extends StatelessWidget {
  final bool canTrial;
  final VoidCallback onTap;

  const _UpgradeBanner({required this.canTrial, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary,
                  cs.primary.withOpacity(0.8),
                  cs.tertiary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tinta Premium',
                        style: tt.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        canTrial
                            ? 'Prueba gratis 7 días — IA ilimitada, audio y más'
                            : 'Desbloquea IA ilimitada, audio y más',
                        style: tt.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge discreto para usuarios premium activos.
class _PremiumActiveBadge extends StatelessWidget {
  final SubscriptionStatus status;
  final VoidCallback onTap;

  const _PremiumActiveBadge({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final label = status.isTrial
        ? 'Prueba gratis · ${status.daysRemaining} días restantes'
        : 'Premium activo · ${status.daysRemaining} días restantes';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: tt.labelMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: cs.primary.withOpacity(0.5), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
