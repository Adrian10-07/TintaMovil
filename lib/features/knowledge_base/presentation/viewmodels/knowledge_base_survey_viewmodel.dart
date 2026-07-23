import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../data/datasources/knowledge_base_prefs.dart';
import '../../domain/entities/knowledge_base_option.dart';
import '../../domain/repositories/knowledge_repository.dart';

enum KbSurveyState { idle, downloading, done, error }

/// ViewModel de la encuesta post-registro: qué bases de conocimiento
/// descargar (indexar localmente) para que Tinta AI las use como contexto.
class KnowledgeBaseSurveyViewModel extends ChangeNotifier {
  final KnowledgeRepository _repo;

  KnowledgeBaseSurveyViewModel(this._repo);

  final Set<String> _selectedIds = {};
  Set<String> get selectedIds => _selectedIds;

  KbSurveyState _state = KbSurveyState.idle;
  KbSurveyState get state => _state;

  /// Progreso de descarga/indexado por kbId (0.0 a 1.0).
  final Map<String, double> _progress = {};
  Map<String, double> get progress => _progress;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isDownloading => _state == KbSurveyState.downloading;

  bool isSelected(String kbId) => _selectedIds.contains(kbId);

  void toggle(String kbId) {
    if (isDownloading) return;
    if (_selectedIds.contains(kbId)) {
      _selectedIds.remove(kbId);
    } else {
      _selectedIds.add(kbId);
    }
    notifyListeners();
  }

  /// Descarga (indexa localmente) las bases seleccionadas y guarda la
  /// selección. Devuelve true si se completó sin errores.
  Future<bool> downloadSelected() async {
    if (_selectedIds.isEmpty) {
      _errorMessage = 'Selecciona al menos una base de conocimiento';
      notifyListeners();
      return false;
    }

    _state = KbSurveyState.downloading;
    _errorMessage = null;
    notifyListeners();

    try {
      for (final option in KnowledgeBaseCatalog.available) {
        if (!_selectedIds.contains(option.id)) continue;

        _progress[option.id] = 0.0;
        notifyListeners();

        final alreadyIndexed = await _repo.isKnowledgeBaseIndexed(option.id);
        if (alreadyIndexed) {
          _progress[option.id] = 1.0;
          notifyListeners();
          continue;
        }

        final markdown = await rootBundle.loadString(option.assetPath);

        await _repo.indexMarkdownKnowledgeBase(
          option.id,
          option.title,
          markdown,
          onProgress: (p) {
            _progress[option.id] = p;
            notifyListeners();
          },
        );
      }

      await KnowledgeBasePrefs.saveSelectedIds(_selectedIds.toList());
      _state = KbSurveyState.done;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'No se pudo descargar: $e';
      _state = KbSurveyState.error;
      notifyListeners();
      return false;
    }
  }

  /// Marca la encuesta como completada sin seleccionar nada
  /// (opción "Ahora no"). No indexa ni descarga nada.
  Future<void> skip(String userId) async {
    await KnowledgeBasePrefs.markSurveyCompleted(userId);
  }
}