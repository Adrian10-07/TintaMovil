import 'dart:io';
import 'package:flutter/material.dart';

import '../../data/datasources/recommendation_upload_datasource.dart';
import '../../../reader/data/services/reading_library_service.dart';

enum UploadState { idle, picking, uploading, success, error }

class UploadBookViewModel extends ChangeNotifier {
  final RecommendationUploadDataSource _dataSource;

  UploadBookViewModel(this._dataSource);

  UploadState _state = UploadState.idle;
  UploadState get state => _state;

  File? _selectedFile;
  File? get selectedFile => _selectedFile;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int? _recomendacionesGeneradas;
  int? get recomendacionesGeneradas => _recomendacionesGeneradas;

  void setSelectedFile(File file) {
    _selectedFile = file;
    _state = UploadState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelection() {
    _selectedFile = null;
    _state = UploadState.idle;
    notifyListeners();
  }

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
    notifyListeners();

    try {
      final n = await _dataSource.generateFromPdf(
        userId: userId,
        pdfFile: _selectedFile!,
        questions: questions,
      );
      _recomendacionesGeneradas = n;
      _state = UploadState.success;

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
      _errorMessage = e.toString();
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