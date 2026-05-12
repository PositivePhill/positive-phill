import 'package:flutter/foundation.dart';
import 'package:positive_phill/models/user_progress.dart';
import 'package:positive_phill/services/storage_service.dart';

class UserProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final Set<String> _sessionPaidIds = {};
  UserProgress _progress = const UserProgress();
  bool _isLoading = true;

  /// Fires with the new level number each time the user levels up.
  final ValueNotifier<int> levelUpNotifier = ValueNotifier(0);

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

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

    final lastOpenDay =
        DateTime(lastOpen.year, lastOpen.month, lastOpen.day);
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
    final oldLevel = _progress.level;
    final newXp = _progress.xp + amount;
    final newLevel = (newXp ~/ 200) + 1;

    _progress = _progress.copyWith(
      xp: newXp,
      level: newLevel,
    );

    notifyListeners();
    await _saveProgress();

    if (newLevel > oldLevel) {
      levelUpNotifier.value = newLevel;
    }
  }

  Future<void> completeSession() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_isSameDay(_progress.lastSessionCompletedDate, today)) {
      return;
    }

    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final dates = List<String>.from(_progress.completedDates);
    if (!dates.contains(todayStr)) {
      dates.add(todayStr);
      // Keep last 90 entries to prevent unbounded growth
      if (dates.length > 90) {
        dates.removeRange(0, dates.length - 90);
      }
    }

    final yesterday = today.subtract(const Duration(days: 1));
    final lastCompleted = _progress.lastSessionCompletedDate;
    final int newStreak;
    if (lastCompleted == null) {
      newStreak = 1;
    } else if (_isSameDay(lastCompleted, yesterday)) {
      newStreak = _progress.streak + 1;
    } else {
      newStreak = 1;
    }

    _progress = _progress.copyWith(
      streak: newStreak,
      lastOpenDate: today,
      lastSessionCompletedDate: today,
      completedDates: dates,
    );

    await addXp(20);
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
    if (!wasFavorite &&
        isNowFavorite &&
        !_sessionPaidIds.contains(affirmationId)) {
      _sessionPaidIds.add(affirmationId);
      try {
        await addXp(10);
      } catch (e) {
        _sessionPaidIds.remove(affirmationId);
        debugPrint('toggleFavorite: addXp failed: $e');
      }
    }

    _progress = _progress.copyWith(favorites: favorites);
    notifyListeners();
    await _saveProgress();
  }

  bool isFavorite(String affirmationId) =>
      _progress.favorites.contains(affirmationId);

  Future<void> incrementExtraPacks() async {
    _progress = _progress.copyWith(
      extraPacksToday: _progress.extraPacksToday + 1,
    );
    notifyListeners();
    await _saveProgress();
  }

  Future<void> resetProgress() async {
    _sessionPaidIds.clear();
    _progress = const UserProgress();
    notifyListeners();
    await _storageService.resetProgress();
  }

  Future<void> _saveProgress() async {
    await _storageService.saveUserProgress(_progress);
  }

  @override
  void dispose() {
    levelUpNotifier.dispose();
    super.dispose();
  }
}
