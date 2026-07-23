import '../../data/datasources/remote_tutor_datasource.dart';
import 'remote_tutor_chat_viewmodel.dart';

/// Mantiene viva una conversación remota por cada documento mientras la
/// app siga corriendo, para que cerrar el chat (ver el PDF) y volver a
/// abrirlo no pierda el historial de mensajes.
///
/// Es un cache en memoria, NO persistencia en disco: si la app se cierra
/// por completo, el historial se pierde igual (eso queda para una fase
/// posterior con SQLite, según lo que ya platicamos).
///
/// Cada documento tiene su propia conversación independiente — abrir el
/// chat de un PDF distinto no mezcla mensajes con el anterior.
class RemoteTutorSessionManager {
  final RemoteTutorDatasource _datasource;
  final Map<String, RemoteTutorChatViewModel> _sessions = {};

  RemoteTutorSessionManager(this._datasource);

  /// Devuelve la conversación existente para este documento, o crea una
  /// nueva la primera vez que se abre.
  RemoteTutorChatViewModel getOrCreate({
    required String remoteDocumentId,
    required String documentContext,
  }) {
    return _sessions.putIfAbsent(
      remoteDocumentId,
          () => RemoteTutorChatViewModel(
        _datasource,
        remoteDocumentId: remoteDocumentId,
        documentContext: documentContext,
      ),
    );
  }

  /// Por si se quiere limpiar explícitamente una conversación (por
  /// ejemplo, un botón "Nueva conversación" en el futuro).
  void clearSession(String remoteDocumentId) {
    _sessions[remoteDocumentId]?.clearChat();
  }

  /// Libera todas las sesiones (por ejemplo al cerrar sesión del usuario).
  void disposeAll() {
    for (final vm in _sessions.values) {
      vm.dispose();
    }
    _sessions.clear();
  }
}