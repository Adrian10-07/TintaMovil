import 'dart:io';
import 'package:flutter/material.dart';

import '../../data/datasources/recommendation_upload_datasource.dart';

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
    notifyListeners();

    try {
      final n = await _dataSource.generateFromPdf(
        userId: userId,
        pdfFile: _selectedFile!,
        questions: questions,
      );
      _recomendacionesGeneradas = n;
      _state = UploadState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state = UploadState.error;
    } finally {
      notifyListeners();
    }
  }
}