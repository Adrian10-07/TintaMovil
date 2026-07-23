import 'package:flutter/foundation.dart';
import '../../data/datasources/premium_remote_datasource.dart';
import '../../domain/entities/plan_info.dart';
import '../../domain/entities/subscription_status.dart';

enum PremiumState { idle, loading, loaded, error }

class PremiumViewModel extends ChangeNotifier {
  final PremiumRemoteDatasource _datasource;

  PremiumState _state = PremiumState.idle;
  PremiumState get state => _state;

  SubscriptionStatus _status = SubscriptionStatus.free();
  SubscriptionStatus get status => _status;

  List<PlanInfo> _plans = [];
  List<PlanInfo> get plans => _plans;

  String? _error;
  String? get error => _error;

  PremiumViewModel(this._datasource);

  /// Carga planes y estado de suscripción en paralelo.
  Future<void> load() async {
    _state = PremiumState.loading;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _datasource.getPlans(),
        _datasource.getSubscriptionStatus(),
      ]);
      _plans = results[0] as List<PlanInfo>;
      _status = results[1] as SubscriptionStatus;
      _state = PremiumState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = PremiumState.error;
      // Fallback: planes estáticos si el API no responde.
      if (_plans.isEmpty) {
        _plans = _defaultPlans();
      }
    }
    notifyListeners();
  }

  /// Activa la prueba gratuita.
  Future<bool> startTrial() async {
    try {
      _status = await _datasource.startTrial();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Crea checkout y retorna la URL para abrir en browser.
  Future<String?> checkout(String plan, String method) async {
    try {
      return await _datasource.createCheckout(plan: plan, method: method);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Refresca solo el estado de suscripción (p.ej. después de pagar).
  Future<void> refreshStatus() async {
    try {
      _status = await _datasource.getSubscriptionStatus();
      notifyListeners();
    } catch (_) {}
  }

  List<PlanInfo> _defaultPlans() => const [
    PlanInfo(tier: 'free', name: 'Gratis', priceMxn: 0, intervalDays: 0,
      description: 'Funciones básicas de lectura',
      features: ['Lectura del catálogo (5 libros/mes)', 'Racha de lectura',
        'Unirse a 2 clubes públicos', 'Tutor AI local (5 msgs/día)']),
    PlanInfo(tier: 'monthly', name: 'Premium Mensual', priceMxn: 49, intervalDays: 30,
      description: 'Todo sin límites, mes a mes',
      features: ['Lectura ilimitada', 'Tutor AI local + remoto ilimitado',
        'Audio TTS', 'Subir PDFs', 'Clubes privados ilimitados', 'Base de conocimiento']),
    PlanInfo(tier: 'annual', name: 'Premium Anual', priceMxn: 399, intervalDays: 365,
      description: 'Ahorra 33%',
      features: ['Todo lo del mensual', 'Ahorro de 33%', 'Soporte prioritario']),
  ];
}
