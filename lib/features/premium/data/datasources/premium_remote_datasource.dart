import '../../../../core/network/http_client.dart';
import '../../domain/entities/plan_info.dart';
import '../../domain/entities/subscription_status.dart';

/// DataSource remoto del microservicio de pagos de Tinta.
class PremiumRemoteDatasource {
  final ApiClient _api;

  static const String _baseUrl =
      'https://tinta-payments-api.onrender.com';

  PremiumRemoteDatasource(this._api);

  /// GET /plans — lista los planes disponibles (no requiere auth).
  Future<List<PlanInfo>> getPlans() async {
    final data = await _api.get('$_baseUrl/plans', auth: false);
    final list = data as List<dynamic>;
    return list
        .map((e) => PlanInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /subscription/me — estado de suscripción del usuario actual.
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    try {
      final data = await _api.get('$_baseUrl/subscription/me', auth: true);
      return SubscriptionStatus.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return SubscriptionStatus.free();
    }
  }

  /// POST /subscription/trial — activa la prueba gratuita.
  Future<SubscriptionStatus> startTrial() async {
    await _api.post('$_baseUrl/subscription/trial', body: {}, auth: true);
    return getSubscriptionStatus();
  }

  /// POST /payments/checkout — crea sesión de checkout en Stripe.
  /// Retorna la URL de checkout para abrir en webview/browser.
  Future<String> createCheckout({
    required String plan,
    required String method,
  }) async {
    final data = await _api.post(
      '$_baseUrl/payments/checkout',
      body: {'plan': plan, 'method': method},
      auth: true,
    );
    final map = data as Map<String, dynamic>;
    return map['checkout_url'] as String;
  }
}