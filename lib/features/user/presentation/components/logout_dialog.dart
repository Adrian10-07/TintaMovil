import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tinta/core/di/service_locator.dart';
import 'package:tinta/core/localization/app_strings.dart';
import 'package:tinta/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/user_viewmodel.dart';

/// Diálogo de confirmación de cierre de sesión.

class LogoutDialog {
  LogoutDialog._();

  /// Muestra el diálogo y, si el usuario confirma, ejecuta el logout.
  static Future<void> show(BuildContext context) async {
    final t = AppStrings.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(t.logout),
        content: Text(t.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              t.logout,
              // Uso labelLarge del tema; solo cambio el color para
              // resaltar acción destructiva.
              style: textTheme.labelLarge?.copyWith(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      _performLogout(context);
    }
  }

  static void _performLogout(BuildContext context) {
    final authVM = sl<AuthViewModel>();

    // 1. Local, instantáneo — esto SIEMPRE funciona, no depende de red.
    context.read<UserViewModel>().clearProfile();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);

    // 2. Revocar el refresh token en el backend, en segundo plano.
    authVM.logout().catchError((_) {});
  }
}