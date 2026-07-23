/// Información de un plan disponible.
class PlanInfo {
  final String tier;       // "free", "monthly", "annual"
  final String name;
  final double priceMxn;
  final int intervalDays;
  final String description;
  final List<String> features;

  const PlanInfo({
    required this.tier,
    required this.name,
    required this.priceMxn,
    required this.intervalDays,
    required this.description,
    required this.features,
  });

  factory PlanInfo.fromJson(Map<String, dynamic> json) => PlanInfo(
    tier: json['tier'] as String,
    name: json['name'] as String,
    priceMxn: (json['price_mxn'] as num).toDouble(),
    intervalDays: (json['interval_days'] as num).toInt(),
    description: json['description'] as String,
    features: (json['features'] as List).cast<String>(),
  );

  bool get isFree => tier == 'free';
  bool get isMonthly => tier == 'monthly';
  bool get isAnnual => tier == 'annual';

  String get priceLabel => isFree
      ? 'Gratis'
      : '\$${priceMxn.toStringAsFixed(0)} MXN';

  String get intervalLabel => isMonthly ? '/mes' : isAnnual ? '/año' : '';
}
