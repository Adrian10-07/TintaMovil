import 'package:shared_preferences/shared_preferences.dart';

/// Persiste localmente qué bases de conocimiento eligió el usuario y si
/// ya completó la encuesta, para no volver a mostrarla en cada login.
class KnowledgeBasePrefs {
  static String _surveyKey(String userId) => 'kb_survey_completed_$userId';
  static const _selectedIdsKey = 'kb_selected_ids';

  /// Si el usuario [userId] ya pasó por la encuesta (aunque haya elegido
  /// "Ahora no" y no haya seleccionado ninguna).
  static Future<bool> isSurveyCompleted(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_surveyKey(userId)) ?? false;
  }

  static Future<void> markSurveyCompleted(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_surveyKey(userId), true);
  }

  /// IDs de las bases de conocimiento seleccionadas (últimas guardadas).
  static Future<List<String>> getSelectedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_selectedIdsKey) ?? [];
  }

  static Future<void> saveSelectedIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedIdsKey, ids);
  }
}