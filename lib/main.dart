import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'globals.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa el motor de flutter_gemma ANTES de setupServiceLocator(),
  // ya que GemmaFlutterTutorDatasource depende de que esto se haya
  // ejecutado para poder descargar/activar el modelo local.
  FlutterGemma.initialize(
    huggingFaceToken: const String.fromEnvironment('HUGGINGFACE_TOKEN'),
    maxDownloadRetries: 10,
  );

  setupServiceLocator();
  await appSettings.load();

  runApp(
    // Solo en debug — en release DevicePreview se desactiva y arranca la
    // app normal, sin overhead.
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (_) => const TintaApp(),
    ),
  );
}