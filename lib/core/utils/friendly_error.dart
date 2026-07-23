String friendlyErrorMessage(Object error) {
  final raw = error.toString().toLowerCase();

  if (raw.contains('socketexception') ||
      raw.contains('failed host lookup') ||
      raw.contains('network is unreachable') ||
      raw.contains('connection refused')) {
    return 'Sin conexión a internet. Revisa tu red e intenta de nuevo.';
  }

  if (raw.contains('timeoutexception') || raw.contains('timed out')) {
    return 'La conexión tardó demasiado. Intenta de nuevo.';
  }

  if (raw.contains('401') || raw.contains('unauthorized')) {
    return 'Tu sesión expiró. Vuelve a iniciar sesión.';
  }

  if (raw.contains('403') || raw.contains('forbidden')) {
    return 'No tienes permiso para hacer esto.';
  }

  if (raw.contains('404') || raw.contains('not found')) {
    return 'No se encontró lo que buscabas.';
  }

  if (raw.contains('409')) {
    return 'Esto aún se está procesando. Intenta en unos segundos.';
  }

  if (raw.contains('500') ||
      raw.contains('502') ||
      raw.contains('503') ||
      raw.contains('server')) {
    return 'El servidor no está disponible en este momento.';
  }

  if (raw.contains('no hay token de sesión')) {
    return 'Debes iniciar sesión para usar esta función.';
  }

  return 'Ocurrió un problema. Intenta de nuevo.';
}

bool isConnectivityError(Object error) {
  final raw = error.toString().toLowerCase();
  return raw.contains('socketexception') ||
      raw.contains('failed host lookup') ||
      raw.contains('network is unreachable') ||
      raw.contains('connection refused') ||
      raw.contains('timeoutexception') ||
      raw.contains('timed out') ||
      raw.contains('error de conexión');
}
