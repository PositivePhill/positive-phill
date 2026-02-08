import 'package:flutter/foundation.dart';
import 'package:positive_phill/models/user_progress.dart';
import 'package:positive_phill/services/storage_service.dart';

class UserProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final Set<String> _sessionPaidIds = {};
  UserProgress _progress = const UserProgress();
  bool _isLoading = true;

  UserProgress get progress => _progress;
  bool get isLoading => _isLoading;

  UserProvider() {
    loadProgress();
  }

  Future<void> loadProgress() async {
    try {
      _progress = await _storageService.loadUserProgress();
      _checkAndUpdateStreak();
    } catch (e) {
      debugPrint('Failed to load progress: $e');
      _progress = const UserProgress();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _checkAndUpdateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastOpen = _progress.lastOpenDate;

    if (lastOpen == null) {
      _progress = _progress.copyWith(lastOpenDate: today);
      _saveProgress();
      return;
    }

    final lastOpenDay = DateTime(lastOpen.year, lastOpen.month, lastOpen.day);
    final daysDifference = today.difference(lastOpenDay).inDays;

    if (daysDifference > 1) {
      _progress = _progress.copyWith(
        streak: 0,
        lastOpenDate: today,
        extraPacksToday: 0,
      );
      _saveProgress();
    } else if (daysDifference == 1) {
      _progress = _progress.copyWith(
        lastOpenDate: today,
        extraPacksToday: 0,
      );
      _saveProgress();
    }
  }

  Future<void> addXp(int amount) async {
    final newXp = _progress.xp + amount;
    final newLevel = (newXp ~/ 200) + 1;
    final leveledUp = newLevel > _progress.level;

    _progress = _progress.copyWith(
      xp: newXp,
      level: newLevel,
    );
    
    notifyListeners();
    await _saveProgress();

    if (leveledUp) {
      debugPrint('Level up! New level: $newLevel');
    }
  }

  Future<void> completeSession() async {
    final newStreak = _progress.streak + 1;
    
    _progress = _progress.copyWith(
      streak: newStreak,
      lastOpenDate: DateTime.now(),
    );
    
    await addXp(20);
    notifyListeners();
  }

  Future<void> toggleFavorite(String affirmationId) async {
    final wasFavorite = _progress.favorites.contains(affirmationId);
    final favorites = List<String>.from(_progress.favorites);

    if (favorites.contains(affirmationId)) {
      favorites.remove(affirmationId);
    } else {
      favorites.add(affirmationId);
    }

    final isNowFavorite = favorites.contains(affirmationId);
    if (!wasFavorite && isNowFavorite && !_sessionPaidIds.contains(affirmationId)) {
      await addXp(10);
      _sessionPaidIds.add(affirmationId);
    }

    _progress = _progress.copyWith(favorites: favorites);
    notifyListeners();
    await _saveProgress();
  }

  bool isFavorite(String affirmationId) => _progress.favorites.contains(affirmationId);

  Future<void> incrementExtraPacks() async {
    _progress = _progress.copyWith(
      extraPacksToday: _progress.extraPacksToday + 1,
    );
    notifyListeners();
    await _saveProgress();
  }

  Future<void> resetProgress() async {
    _progress = const UserProgress();
    notifyListeners();
    await _storageService.resetProgress();
  }

  Future<void> _saveProgress() async {
    await _storageService.saveUserProgress(_progress);
  }
}
