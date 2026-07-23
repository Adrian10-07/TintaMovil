import 'package:flutter/material.dart';

/// Transición fluida tipo "fade + slide sutil" para navegación entre
/// pantallas — se siente más suave que el slide brusco por defecto de
/// Android. Úsala en vez de MaterialPageRoute cuando quieras que el
/// cambio de pantalla se sienta más natural (por ejemplo, al navegar
/// desde la barra inferior).
Route<T> fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

      final fade = Tween<double>(begin: 0, end: 1).animate(curved);
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(curved);

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}