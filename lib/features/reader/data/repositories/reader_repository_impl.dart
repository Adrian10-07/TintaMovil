import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/reader_repository.dart';
import '../datasources/reader_remote_datasource.dart';

class ReaderRepositoryImpl implements ReaderRepository {
  final ReaderRemoteDataSource _remoteDataSource;

  ReaderRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> saveProgress(ReadingProgress progress) async {
    try {
      await _remoteDataSource.saveProgress(progress);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ReadingProgress?> getProgress(String bookId) async {
    try {
      return await _remoteDataSource.getProgress(bookId);
    } catch (e) {
      rethrow;
    }
  }
}