import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Detecta si hay conectividad a internet real, no solo si hay una
class ConnectivityChecker {
  /// Verifica conectividad en dos pasos:
  ///   1. Consulta rápida al SO: ¿hay alguna interfaz de red activa?
  ///      (evita intentar DNS si el radio está apagado, ahorra tiempo)
  ///   2. Si hay interfaz, confirma con una resolución DNS real.
  ///
  /// Timeout corto (2s) para no bloquear la apertura del chat mucho
  /// tiempo si la red está caída.
  Future<bool> hasInternet() async {
    try {
      final result = await Connectivity().checkConnectivity();
      final hasInterface = !result.contains(ConnectivityResult.none);
      if (!hasInterface) return false;

      // Confirmación real: intenta resolver un dominio conocido.
      final lookup = await InternetAddress.lookup('huggingface.co')
          .timeout(const Duration(seconds: 2));
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
