import 'dart:io';
import 'package:flutter/material.dart';

import '../../data/datasources/recommendation_upload_datasource.dart';
import '../../../reader/data/services/reading_library_service.dart';
import '../../../notifications/data/services/notification_service.dart';
import '../../data/services/recent_documents_service.dart';

enum UploadState { idle, picking, uploading, success, error }

/// ViewModel de la vista "Sube un libro para recibir recomendaciones".
class UploadBookViewModel extends ChangeNotifier {
  final RecommendationUploadDataSource _dataSource;

  UploadBookViewModel(this._dataSource);

  UploadState _state = UploadState.idle;
  UploadState get state => _state;

  File? _selectedFile;
  File? get selectedFile => _selectedFile;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isOfflineError = false;
  bool get isOfflineError => _isOfflineError;

  int? _recomendacionesGeneradas;
  int? get recomendacionesGeneradas => _recomendacionesGeneradas;

  void setSelectedFile(File file) {
    _selectedFile = file;
    _state = UploadState.idle;
    _errorMessage = null;
    _isOfflineError = false;
    notifyListeners();
  }

  void clearSelection() {
    _selectedFile = null;
    _state = UploadState.idle;
    _isOfflineError = false;
    notifyListeners();
  }

  /// Sube el PDF seleccionado y genera las recomendaciones.
  Future<void> generate({
    required String userId,
    List<String> questions = const [],
  }) async {
    if (_selectedFile == null) {
      _errorMessage = 'Primero selecciona un PDF';
      _state = UploadState.error;
      notifyListeners();
      return;
    }

    _state = UploadState.uploading;
    _errorMessage = null;
    _isOfflineError = false;
    notifyListeners();

    try {
      final n = await _dataSource.generateFromPdf(
        userId: userId,
        pdfFile: _selectedFile!,
        questions: questions,
      );
      _recomendacionesGeneradas = n;
      _state = UploadState.success;

      final titulo = _fileNameFrom(_selectedFile!.path);

      // Guarda el documento con su metadata REAL (páginas leídas del PDF,
      // tamaño en disco) para que "Recientes" no sea más un mock.
      await RecentDocumentsService.registerUpload(
        userId,
        file: _selectedFile!,
        recommendationsCount: n,
      );

      // Notificación de que el libro/documento se subió y analizó con
      // éxito, sin importar cuántas recomendaciones haya encontrado.
      await NotificationService.add(
        userId,
        type: 'upload',
        title: 'Documento subido',
        body: '"$titulo" se analizó correctamente y ya puedes leerlo.',
      );

      if (n > 0) {
        await NotificationService.add(
          userId,
          type: 'recommendation',
          title: 'Nuevas recomendaciones te pueden interesar',
          body: n == 1
              ? 'Encontramos 1 recomendación basada en "$titulo".'
              : 'Encontramos $n recomendaciones basadas en "$titulo".',
        );
      }

      // No hay lector real para PDFs subidos, así que no hay progreso de
      // lectura verdadero que trackear. Como aproximación, se usa el
      // número de recomendaciones generadas por el análisis ML sobre un
      // total esperado de 5 como referencia, para que el documento
      // aparezca en "Leyendo actualmente" con un % representativo del
      // avance del análisis (no de páginas leídas).
      const totalEsperado = 5;
      await ReadingLibraryService.upsert(
        userId,
        ReadingLibraryEntry(
          bookId: 'upload:${_selectedFile!.path}',
          title: _fileNameFrom(_selectedFile!.path),
          author: 'Documento subido — análisis ML',
          currentPage: n.clamp(0, totalEsperado),
          totalPages: totalEsperado,
          lastReadAt: DateTime.now(),
        ),
      );
    } catch (e) {
      final raw = e.toString();

      // El datasource envuelve fallos de red en un ClientException con
      // SocketException/"Failed host lookup" por debajo. Se detecta aquí
      // por texto (no hay un tipo de excepción propio de "sin internet")
      // para mostrar un mensaje claro en vez del stack técnico crudo.
      final pareceSinInternet = raw.contains('SocketException') ||
          raw.contains('Failed host lookup') ||
          raw.contains('Connection failed') ||
          raw.contains('Network is unreachable');

      if (pareceSinInternet) {
        _isOfflineError = true;
        _errorMessage =
        'Estás sin conexión a internet. Las recomendaciones no están disponibles en este momento — en cuanto tengas internet, podrás generarlas para este documento.';
      } else {
        _isOfflineError = false;
        _errorMessage = raw;
      }
      _state = UploadState.error;
    } finally {
      notifyListeners();
    }
  }

  String _fileNameFrom(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }
}