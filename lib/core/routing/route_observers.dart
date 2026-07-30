import 'package:flutter/material.dart';

/// Observer global de navegación.
///
/// Permite que pantallas como Home se enteren cuando vuelven a quedar
/// visibles tras un pop (por ejemplo, al regresar de leer un libro), sin
/// importar cuántas rutas intermedias se hayan apilado encima.

final RouteObserver<PageRoute> appRouteObserver = RouteObserver<PageRoute>();