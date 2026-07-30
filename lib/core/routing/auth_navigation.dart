import 'package:flutter/material.dart';

import '../di/service_locator.dart';
import '../../features/tutorAI/data/services/model_download_service.dart';
import 'app_routes.dart';

/// Navegación post-auth.

class AuthNavigation {
  AuthNavigation._();


  static Future<void> afterAuthSuccess(
      BuildContext ctx, {
        bool isNewAccount = false,
      }) async {
    if (!ctx.mounted) return;

    // Precarga en background — no bloquea la navegación. Si falla, el
    // usuario simplemente entra a Home sin modelo listo aún.
    sl<ModelDownloadService>().restoreState().then((_) {
      sl<ModelDownloadService>().startDownload();
    });

    Navigator.pushReplacementNamed(ctx, AppRoutes.home);
  }
}