import 'package:flutter/foundation.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/model_download_status.dart';
import '../../domain/repositories/tutor_repository.dart';
import '../datasources/tutor_llm_datasource.dart';

class TutorRepositoryImpl implements TutorRepository {
  final TutorLlmDatasource _datasource;

  TutorRepositoryImpl(this._datasource);

  @override
  Stream<ModelDownloadStatus> get downloadStatus => _datasource.statusStream;

  @override
  Future<void> ensureModelReady() => _datasource.ensureModelReady();

  @override
  Stream<String> generateResponse({
    required List<ChatMessage> history,
    String? documentContext,
  }) {
    final systemPrompt = documentContext != null
        ? 'Eres Tinta AI, un tutor amigable que ayuda al estudiante con la lectura. '
            'El usuario está leyendo: "$documentContext". '
            'Responde preguntas sobre el contenido de forma educativa y motivadora.'
        : 'Eres Tinta AI, un tutor amigable. '
            'Ayudas al estudiante con sus dudas de forma educativa y motivadora.';

    return _datasource.generate(
      systemPrompt: systemPrompt,
      history: history,
    );
  }

  @override
  Future<void> dispose() => _datasource.dispose();
}
