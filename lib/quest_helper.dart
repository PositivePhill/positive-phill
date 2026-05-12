import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:positive_phill/models/daily_quests.dart';
import 'package:positive_phill/providers/quest_provider.dart';
import 'package:positive_phill/providers/user_provider.dart';

/// Centralised quest payout helper.
///
/// All callers must use this instead of duplicating the two-provider call.
/// Returns the XP awarded (0 if quest was already completed today).
Future<int> completeQuest(BuildContext context, QuestType type) async {
  final xp = await context.read<QuestProvider>().markCompleted(type);
  if (xp > 0 && context.mounted) {
    await context.read<UserProvider>().addXp(xp);
  }
  return xp;
}
