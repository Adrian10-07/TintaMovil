import '../../data/datasources/remote_tutor_datasource.dart';
import 'remote_tutor_chat_viewmodel.dart';

/// Mantiene viva una conversación remota por "clave de sesión" mientras
/// la app siga corriendo, para que cerrar el chat y volver a abrirlo no
/// pierda el historial.
///
/// La clave es el `remoteDocumentId` cuando existe (modo RAG sobre un
/// PDF). Cuando es null (chat general, ej. desde ReaderView con un
/// EPUB), se usa `documentContext` como clave — así cada libro/pantalla
/// mantiene su propia conversación aunque no haya document_id real.
class RemoteTutorSessionManager {
  final RemoteTutorDatasource _datasource;
  final Map<String, RemoteTutorChatViewModel> _sessions = {};

  RemoteTutorSessionManager(this._datasource);

  String _keyFor({String? remoteDocumentId, required String documentContext}) {
    return remoteDocumentId ?? 'general:$documentContext';
  }

  RemoteTutorChatViewModel getOrCreate({
    String? remoteDocumentId,
    required String documentContext,
  }) {
    final key = _keyFor(
      remoteDocumentId: remoteDocumentId,
      documentContext: documentContext,
    );
    return _sessions.putIfAbsent(
      key,
          () => RemoteTutorChatViewModel(
        _datasource,
        remoteDocumentId: remoteDocumentId,
        documentContext: documentContext,
      ),
    );
  }

  void clearSession({String? remoteDocumentId, required String documentContext}) {
    final key = _keyFor(
      remoteDocumentId: remoteDocumentId,
      documentContext: documentContext,
    );
    _sessions[key]?.clearChat();
  }

  void disposeAll() {
    for (final vm in _sessions.values) {
      vm.dispose();
    }
    _sessions.clear();
  }
}
