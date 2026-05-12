class DailyFortune {
  final String energy;
  final String luckyFocus;
  final String message;

  const DailyFortune({
    required this.energy,
    required this.luckyFocus,
    required this.message,
  });
}

class FortuneService {
  FortuneService._();

  static DailyFortune getToday() {
    final now = DateTime.now();
    // Deterministic daily seed — stable all day, different every day
    final seed = now.year * 1000 + now.month * 31 + now.day;
    final index = seed % _fortunes.length;
    return _fortunes[index];
  }

  static const List<DailyFortune> _fortunes = [
    DailyFortune(
      energy: 'Reset & Clarity',
      luckyFocus: 'Gratitude',
      message: 'A small calm action today creates bigger momentum tomorrow.',
    ),
    DailyFortune(
      energy: 'Creative Flow',
      luckyFocus: 'Confidence',
      message: 'Your best ideas arrive when you trust the process.',
    ),
    DailyFortune(
      energy: 'Steady Strength',
      luckyFocus: 'Discipline',
      message: 'Slow and consistent builds what speed alone cannot.',
    ),
    DailyFortune(
      energy: 'Open Heart',
      luckyFocus: 'Healing',
      message: 'Accepting where you are is the first step forward.',
    ),
    DailyFortune(
      energy: 'Sharp Mind',
      luckyFocus: 'Focus',
      message: 'One clear decision today is worth ten scattered ones.',
    ),
    DailyFortune(
      energy: 'Gentle Power',
      luckyFocus: 'Calm',
      message: 'Softness is not weakness — it is sustainable force.',
    ),
    DailyFortune(
      energy: 'Brave Start',
      luckyFocus: 'Confidence',
      message: 'You do not have to feel ready to begin.',
    ),
    DailyFortune(
      energy: 'Quiet Victory',
      luckyFocus: 'Discipline',
      message: 'The work you do when no one is watching shapes who you become.',
    ),
    DailyFortune(
      energy: 'Full Presence',
      luckyFocus: 'Gratitude',
      message: 'Being here fully is its own kind of achievement.',
    ),
    DailyFortune(
      energy: 'New Perspective',
      luckyFocus: 'Healing',
      message: 'A fresh angle on a old problem is sometimes all you need.',
    ),
    DailyFortune(
      energy: 'Inner Warmth',
      luckyFocus: 'Calm',
      message: 'Kindness toward yourself makes everything else easier.',
    ),
    DailyFortune(
      energy: 'Rising Tide',
      luckyFocus: 'Confidence',
      message: 'Every honest effort lifts you, even when results are not yet visible.',
    ),
    DailyFortune(
      energy: 'Deep Roots',
      luckyFocus: 'Discipline',
      message: 'Consistency is not glamorous — it is powerful.',
    ),
    DailyFortune(
      energy: 'Morning Light',
      luckyFocus: 'Focus',
      message: 'Today is a clean page. What you write first matters.',
    ),
    DailyFortune(
      energy: 'Flowing Easy',
      luckyFocus: 'Calm',
      message: 'Resistance softens when you stop fighting the current.',
    ),
    DailyFortune(
      energy: 'Honest Ground',
      luckyFocus: 'Healing',
      message: 'Progress built on truth lasts longer than progress built on pretending.',
    ),
    DailyFortune(
      energy: 'Bright Spark',
      luckyFocus: 'Confidence',
      message: 'Something small you do today will matter more than you expect.',
    ),
    DailyFortune(
      energy: 'Focused Calm',
      luckyFocus: 'Focus',
      message: 'Doing one thing well creates more peace than rushing through many.',
    ),
    DailyFortune(
      energy: 'Grateful Eyes',
      luckyFocus: 'Gratitude',
      message: 'Looking for what is good is a skill that grows with practice.',
    ),
    DailyFortune(
      energy: 'Bold & Gentle',
      luckyFocus: 'Confidence',
      message: 'Being strong and being kind are not opposites — they are partners.',
    ),
    DailyFortune(
      energy: 'Clear Signal',
      luckyFocus: 'Focus',
      message: 'When you know your priority, every decision becomes simpler.',
    ),
    DailyFortune(
      energy: 'Soft Landing',
      luckyFocus: 'Calm',
      message: 'Rest is productive. Stillness is not the same as stopping.',
    ),
    DailyFortune(
      energy: 'True Grit',
      luckyFocus: 'Discipline',
      message: 'Small daily choices compound into the person you are becoming.',
    ),
    DailyFortune(
      energy: 'Open Hands',
      luckyFocus: 'Gratitude',
      message: 'Releasing what no longer serves you makes space for what will.',
    ),
    DailyFortune(
      energy: 'Steady Pulse',
      luckyFocus: 'Healing',
      message: 'Healing is not linear, and that is completely fine.',
    ),
    DailyFortune(
      energy: 'Curious Mind',
      luckyFocus: 'Focus',
      message: 'Approaching challenges with curiosity removes half their weight.',
    ),
    DailyFortune(
      energy: 'Full Charge',
      luckyFocus: 'Confidence',
      message: 'Your energy matters. Protect and direct it with intention.',
    ),
    DailyFortune(
      energy: 'Warm Ground',
      luckyFocus: 'Gratitude',
      message: 'The people and moments you appreciate are already a form of wealth.',
    ),
    DailyFortune(
      energy: 'Turning Point',
      luckyFocus: 'Discipline',
      message: 'Today might be the day a small choice sets a larger direction.',
    ),
    DailyFortune(
      energy: 'Still Waters',
      luckyFocus: 'Calm',
      message: 'Underneath any storm, your deeper self remains steady.',
    ),
    DailyFortune(
      energy: 'Second Wind',
      luckyFocus: 'Confidence',
      message: 'Starting again after a pause is a sign of strength, not failure.',
    ),
    DailyFortune(
      energy: 'Gentle Push',
      luckyFocus: 'Discipline',
      message: 'The nudge you need today is usually smaller than you think.',
    ),
    DailyFortune(
      energy: 'Clear Path',
      luckyFocus: 'Focus',
      message: 'Simplifying what you want makes the route much easier to walk.',
    ),
    DailyFortune(
      energy: 'Full Bloom',
      luckyFocus: 'Healing',
      message: 'Growth shows up at its own pace — yours is right on time.',
    ),
    DailyFortune(
      energy: 'Anchored',
      luckyFocus: 'Calm',
      message: 'What grounds you is already within you — return to it.',
    ),
    DailyFortune(
      energy: 'Honest Effort',
      luckyFocus: 'Discipline',
      message: 'Doing your genuine best is always enough for today.',
    ),
    DailyFortune(
      energy: 'Radiant Start',
      luckyFocus: 'Confidence',
      message: 'The version of you that shows up today has something useful to offer.',
    ),
    DailyFortune(
      energy: 'Deep Gratitude',
      luckyFocus: 'Gratitude',
      message: 'Noticing the small goods makes the larger picture feel more alive.',
    ),
    DailyFortune(
      energy: 'Tender Care',
      luckyFocus: 'Healing',
      message: 'Looking after yourself is not optional — it is the foundation.',
    ),
    DailyFortune(
      energy: 'Momentum',
      luckyFocus: 'Focus',
      message: 'One step taken with intention is worth more than ten taken in doubt.',
    ),
    DailyFortune(
      energy: 'Inner Peace',
      luckyFocus: 'Calm',
      message: 'Peace is not found when everything is perfect — it is practiced daily.',
    ),
    DailyFortune(
      energy: 'Sunrise Energy',
      luckyFocus: 'Confidence',
      message: 'A fresh day is a fresh canvas. Today belongs to you.',
    ),
  ];
}
