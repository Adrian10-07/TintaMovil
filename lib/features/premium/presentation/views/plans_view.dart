import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/plan_info.dart';
import '../viewmodels/premium_viewmodel.dart';

/// Pantalla completa de planes y suscripción.
class PlansView extends StatefulWidget {
  const PlansView({super.key});

  @override
  State<PlansView> createState() => _PlansViewState();
}

class _PlansViewState extends State<PlansView> {
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

  Future<void> _handleTrial() async {
    final ok = await _vm.startTrial();
    if (ok && mounted) {
      // Mostrar pantalla de éxito y volver al home.
      await _showSuccessAndGoHome(
        title: '¡Prueba activada!',
        subtitle: 'Disfruta 7 días de todas las funciones Premium.',
        icon: Icons.rocket_launch_rounded,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_vm.error ?? 'No se pudo activar la prueba')),
      );
    }
  }

  Future<void> _handleCheckout(PlanInfo plan) async {
    // Solo tarjeta — método fijo.
    final url = await _vm.checkout(plan.tier, 'card');
    if (url != null) {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Cuando el usuario regresa del browser, refrescar estado.
      if (mounted) {
        await Future.delayed(const Duration(seconds: 2));
        await _vm.refreshStatus();

        if (_vm.status.isPremium && mounted) {
          await _showSuccessAndGoHome(
            title: '¡Ya eres Premium!',
            subtitle: 'Todas las funciones desbloqueadas. Disfruta Tinta al máximo.',
            icon: Icons.workspace_premium_rounded,
          );
        }
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_vm.error ?? 'Error al crear el checkout')),
      );
    }
  }

  /// Muestra una pantalla de éxito con animación y vuelve al home.
  Future<void> _showSuccessAndGoHome({
    required String title,
    required String subtitle,
    required IconData icon,
  }) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _SuccessScreen(
          title: title,
          subtitle: subtitle,
          icon: icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final status = _vm.status;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes'),
        centerTitle: true,
      ),
      body: _vm.state == PremiumState.loading && _vm.plans.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          children: [
            // Status actual — si ya es premium
            if (status.isPremium)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.isTrial ? 'Prueba gratuita activa' : 'Premium activo',
                            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${status.daysRemaining} días restantes',
                            style: tt.bodySmall?.copyWith(color: cs.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Header
            if (!status.isPremium) ...[
              Icon(Icons.workspace_premium_rounded, size: 56, color: cs.primary),
              const SizedBox(height: 12),
              Text('Elige tu plan', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'Desbloquea todo el potencial de Tinta',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
            ],

            // Cards de planes (solo monthly y annual)
            ..._vm.plans.where((p) => !p.isFree).map((plan) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PlanCard(
                plan: plan,
                isCurrentPlan: status.plan == plan.tier,
                isPremium: status.isPremium,
                onSubscribe: () => _handleCheckout(plan),
              ),
            )),

            // Indicador de método de pago (solo tarjeta)
            if (!status.isPremium) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.credit_card_rounded, size: 20, color: cs.primary),
                    const SizedBox(width: 10),
                    Text(
                      'Pago seguro con tarjeta',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Icon(Icons.lock_rounded, size: 16, color: cs.onSurfaceVariant.withOpacity(0.5)),
                  ],
                ),
              ),
            ],

            // Trial button
            if (status.canStartTrial && !status.isPremium) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                '¿No estás seguro?',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Prueba todas las funciones premium gratis durante 7 días. Sin tarjeta de crédito.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _handleTrial,
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('Iniciar prueba gratuita'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],

            // Plan free features
            const SizedBox(height: 24),
            ..._vm.plans.where((p) => p.isFree).map((plan) => _FreePlanSection(plan: plan)),
          ],
        ),
      ),
    );
  }
}

// ── Pantalla de éxito ─────────────────────────────────────────────

class _SuccessScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SuccessScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  State<_SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<_SuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Volver al home después de 3 segundos.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: cs.onPrimary, size: 48),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                widget.title,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  widget.subtitle,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Ir al inicio'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Plan Card ─────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final PlanInfo plan;
  final bool isCurrentPlan;
  final bool isPremium;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.isPremium,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isBest = plan.isAnnual;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isBest ? cs.primary : cs.outline.withOpacity(0.3),
          width: isBest ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (isBest)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Text(
                'Mejor valor — ahorra 33%',
                textAlign: TextAlign.center,
                style: tt.labelSmall?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w700),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(plan.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(plan.priceLabel, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)),
                  ],
                ),
                if (plan.intervalLabel.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(plan.intervalLabel, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                const SizedBox(height: 12),
                ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_rounded, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: tt.bodySmall)),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: isCurrentPlan
                      ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Plan actual'),
                  )
                      : FilledButton(
                    onPressed: isPremium ? null : onSubscribe,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(isPremium ? 'Ya eres Premium' : 'Pagar con tarjeta'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Free Plan Section ─────────────────────────────────────────────

class _FreePlanSection extends StatelessWidget {
  final PlanInfo plan;
  const _FreePlanSection({required this.plan});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plan Gratuito incluye:', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...plan.features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.remove_rounded, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text(f, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}