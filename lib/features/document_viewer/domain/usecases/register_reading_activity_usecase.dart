import '../../../achievements/data/services/achievement_service.dart';
import '../../../home/data/services/streak_service.dart';
import '../../../recommendations/data/services/recent_documents_service.dart';
import '../../../user/presentation/viewmodels/user_viewmodel.dart';

/// Registra que el usuario abrió un documento de verdad: cuenta para su
/// racha de lectura y puede desbloquear logros por número de subidas.

class RegisterReadingActivityUseCase {
  final UserViewModel _userViewModel;

  RegisterReadingActivityUseCase({required UserViewModel userViewModel})
      : _userViewModel = userViewModel;

  Future<void> call() async {
    if (_userViewModel.profile == null) {
      await _userViewModel.loadProfile();
    }
    final userId = _userViewModel.profile?.id;
    if (userId == null) return;

    await StreakService.registerVisit(userId);

    final uploads = await RecentDocumentsService.getAll(userId);
    await AchievementService.checkUploads(userId, uploads.length);
  }
}