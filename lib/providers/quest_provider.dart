import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:positive_phill/models/daily_quests.dart';
import 'package:positive_phill/services/storage_service.dart';

class QuestProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  DailyQuests _quests = const DailyQuests();
  bool _loaded = false;

  DailyQuests get quests => _quests;
  bool get isLoaded => _loaded;

  QuestProvider() {
    _load();
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.getDailyQuestsJson();
      if (raw != null) {
        final loaded = DailyQuests.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        // Reset state if the stored date is not today
        _quests = loaded.date == _todayString()
            ? loaded
            : DailyQuests(date: _todayString());
      } else {
        _quests = DailyQuests(date: _todayString());
      }
    } catch (e) {
      debugPrint('QuestProvider: failed to load: $e');
      _quests = DailyQuests(date: _todayString());
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      await _storage.setDailyQuestsJson(jsonEncode(_quests.toJson()));
    } catch (e) {
      debugPrint('QuestProvider: failed to save: $e');
    }
  }

  /// Marks a quest complete and returns the XP to award.
  /// Returns 0 if already completed today.
  /// Also returns the all-complete bonus XP (15) once, on the completing quest.
  Future<int> markCompleted(QuestType type) async {
    // Guard: refresh date check in case the app was left open past midnight
    final today = _todayString();
    if (_quests.date != today) {
      _quests = DailyQuests(date: today);
    }

    if (_quests.isCompleted(type)) return 0;

    int xpEarned = 5; // base quest XP
    final updated = Set<QuestType>.from(_quests.completed)..add(type);
    _quests = _quests.copyWith(completed: updated);

    // All-complete bonus — paid exactly once via bonusPaid flag
    if (_quests.allComplete && !_quests.bonusPaid) {
      xpEarned += 15;
      _quests = _quests.copyWith(bonusPaid: true);
    }

    notifyListeners();
    await _save();
    return xpEarned;
  }

  /// Clears quest state (called from UserProvider.resetProgress path)
  Future<void> reset() async {
    _quests = DailyQuests(date: _todayString());
    notifyListeners();
    await _storage.clearDailyQuests();
  }
}
