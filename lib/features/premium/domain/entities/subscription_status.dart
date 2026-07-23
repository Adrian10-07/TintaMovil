/// Estado actual de la suscripción del usuario.
class SubscriptionStatus {
  final String plan;
  final bool isPremium;
  final bool isTrial;
  final bool canStartTrial;
  final DateTime? activeUntil;
  final DateTime? trialUntil;

  const SubscriptionStatus({
    required this.plan,
    required this.isPremium,
    required this.isTrial,
    required this.canStartTrial,
    this.activeUntil,
    this.trialUntil,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) =>
      SubscriptionStatus(
        plan: json['plan'] as String,
        isPremium: json['is_premium'] as bool,
        isTrial: json['is_trial'] as bool,
        canStartTrial: json['can_start_trial'] as bool,
        activeUntil: json['active_until'] != null
            ? DateTime.parse(json['active_until'] as String)
            : null,
        trialUntil: json['trial_until'] != null
            ? DateTime.parse(json['trial_until'] as String)
            : null,
      );

  factory SubscriptionStatus.free() => const SubscriptionStatus(
    plan: 'free',
    isPremium: false,
    isTrial: false,
    canStartTrial: true,
  );

  /// Fecha hasta la que dura el acceso premium (trial o pagado).
  DateTime? get premiumUntil => activeUntil ?? trialUntil;

  /// Días restantes de premium.
  int get daysRemaining {
    final until = premiumUntil;
    if (until == null) return 0;
    return until.difference(DateTime.now()).inDays;
  }
}
