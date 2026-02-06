import 'package:positive_phill/models/affirmation.dart';

class AffirmationsService {
  static final List<Affirmation> _allAffirmations = [
    // Confidence affirmations
    const Affirmation(id: 'conf_1', text: 'I am confident in my abilities and trust in my decisions.', categories: [AffirmationCategory.confidence]),
    const Affirmation(id: 'conf_2', text: 'I radiate self-assurance and inspire others with my presence.', categories: [AffirmationCategory.confidence]),
    const Affirmation(id: 'conf_3', text: 'I believe in myself and embrace every challenge with courage.', categories: [AffirmationCategory.confidence]),
    const Affirmation(id: 'conf_4', text: 'My confidence grows stronger with every step I take forward.', categories: [AffirmationCategory.confidence]),
    const Affirmation(id: 'conf_5', text: 'I am worthy of success and all the good things life offers.', categories: [AffirmationCategory.confidence]),
    const Affirmation(id: 'conf_6', text: 'I trust my intuition and make decisions with clarity.', categories: [AffirmationCategory.confidence]),
    const Affirmation(id: 'conf_7', text: 'I am becoming a better version of myself every day.', categories: [AffirmationCategory.confidence]),
    const Affirmation(id: 'conf_8', text: 'I stand tall, speak boldly, and own my unique power.', categories: [AffirmationCategory.confidence]),
    
    // Calm affirmations
    const Affirmation(id: 'calm_1', text: 'I am at peace with myself and the world around me.', categories: [AffirmationCategory.calm]),
    const Affirmation(id: 'calm_2', text: 'I breathe deeply and release all tension from my body.', categories: [AffirmationCategory.calm]),
    const Affirmation(id: 'calm_3', text: 'Serenity flows through me, calming my mind and soul.', categories: [AffirmationCategory.calm]),
    const Affirmation(id: 'calm_4', text: 'I choose peace over worry, and trust that all is well.', categories: [AffirmationCategory.calm]),
    const Affirmation(id: 'calm_5', text: 'My mind is clear, my heart is light, and I am present.', categories: [AffirmationCategory.calm]),
    const Affirmation(id: 'calm_6', text: 'I release what I cannot control and embrace the moment.', categories: [AffirmationCategory.calm]),
    const Affirmation(id: 'calm_7', text: 'Tranquility surrounds me and fills me with gentle ease.', categories: [AffirmationCategory.calm]),
    const Affirmation(id: 'calm_8', text: 'I am safe, supported, and completely at peace.', categories: [AffirmationCategory.calm]),
    
    // Gratitude affirmations
    const Affirmation(id: 'grat_1', text: 'I am grateful for the abundance that flows into my life.', categories: [AffirmationCategory.gratitude]),
    const Affirmation(id: 'grat_2', text: 'Every day brings new blessings I appreciate deeply.', categories: [AffirmationCategory.gratitude]),
    const Affirmation(id: 'grat_3', text: 'I appreciate the beauty in every moment and every person.', categories: [AffirmationCategory.gratitude]),
    const Affirmation(id: 'grat_4', text: 'My heart overflows with thankfulness for all I have.', categories: [AffirmationCategory.gratitude]),
    const Affirmation(id: 'grat_5', text: 'I am blessed beyond measure and recognize my good fortune.', categories: [AffirmationCategory.gratitude]),
    const Affirmation(id: 'grat_6', text: 'I give thanks for both the big and small joys in life.', categories: [AffirmationCategory.gratitude]),
    const Affirmation(id: 'grat_7', text: 'Gratitude transforms my perspective and opens my heart.', categories: [AffirmationCategory.gratitude]),
    const Affirmation(id: 'grat_8', text: 'I celebrate my progress and honor how far I have come.', categories: [AffirmationCategory.gratitude]),
    
    // Discipline affirmations
    const Affirmation(id: 'disc_1', text: 'I am committed to my goals and take consistent action.', categories: [AffirmationCategory.discipline]),
    const Affirmation(id: 'disc_2', text: 'My discipline creates the life I desire and deserve.', categories: [AffirmationCategory.discipline]),
    const Affirmation(id: 'disc_3', text: 'I show up for myself daily with dedication and focus.', categories: [AffirmationCategory.discipline]),
    const Affirmation(id: 'disc_4', text: 'I have the willpower to overcome any obstacle in my path.', categories: [AffirmationCategory.discipline]),
    const Affirmation(id: 'disc_5', text: 'Every choice I make aligns with my highest intentions.', categories: [AffirmationCategory.discipline]),
    const Affirmation(id: 'disc_6', text: 'I am patient and persistent in pursuing my dreams.', categories: [AffirmationCategory.discipline]),
    const Affirmation(id: 'disc_7', text: 'My habits shape my future, and I choose wisely.', categories: [AffirmationCategory.discipline]),
    const Affirmation(id: 'disc_8', text: 'I honor my commitments and stay true to my word.', categories: [AffirmationCategory.discipline]),
    
    // Healing affirmations
    const Affirmation(id: 'heal_1', text: 'I am healing and growing stronger every single day.', categories: [AffirmationCategory.healing]),
    const Affirmation(id: 'heal_2', text: 'My body, mind, and spirit are in perfect harmony.', categories: [AffirmationCategory.healing]),
    const Affirmation(id: 'heal_3', text: 'I release past pain and embrace a brighter future.', categories: [AffirmationCategory.healing]),
    const Affirmation(id: 'heal_4', text: 'Love and light flow through me, healing all wounds.', categories: [AffirmationCategory.healing]),
    const Affirmation(id: 'heal_5', text: 'I forgive myself and others, freeing my heart to heal.', categories: [AffirmationCategory.healing]),
    const Affirmation(id: 'heal_6', text: 'Every breath I take restores balance and wellness.', categories: [AffirmationCategory.healing]),
    const Affirmation(id: 'heal_7', text: 'I am worthy of healing, peace, and abundant health.', categories: [AffirmationCategory.healing]),
    const Affirmation(id: 'heal_8', text: 'My recovery is a journey I honor with compassion.', categories: [AffirmationCategory.healing]),
    
    // Focus affirmations
    const Affirmation(id: 'focus_1', text: 'I am fully present and deeply focused on what matters.', categories: [AffirmationCategory.focus]),
    const Affirmation(id: 'focus_2', text: 'My mind is sharp, clear, and ready to achieve greatness.', categories: [AffirmationCategory.focus]),
    const Affirmation(id: 'focus_3', text: 'I eliminate distractions and channel all my energy wisely.', categories: [AffirmationCategory.focus]),
    const Affirmation(id: 'focus_4', text: 'I am laser-focused on my priorities and accomplish them.', categories: [AffirmationCategory.focus]),
    const Affirmation(id: 'focus_5', text: 'Concentration flows through me effortlessly and naturally.', categories: [AffirmationCategory.focus]),
    const Affirmation(id: 'focus_6', text: 'I direct my attention toward what brings me closer to my goals.', categories: [AffirmationCategory.focus]),
    const Affirmation(id: 'focus_7', text: 'Every moment I dedicate to focus creates lasting results.', categories: [AffirmationCategory.focus]),
    const Affirmation(id: 'focus_8', text: 'I am in control of my mind and where I place my energy.', categories: [AffirmationCategory.focus]),
    
    // Social affirmations
    const Affirmation(id: 'social_1', text: 'I connect authentically and build meaningful relationships.', categories: [AffirmationCategory.social]),
    const Affirmation(id: 'social_2', text: 'People are drawn to my warmth and positive energy.', categories: [AffirmationCategory.social]),
    const Affirmation(id: 'social_3', text: 'I communicate with confidence, kindness, and clarity.', categories: [AffirmationCategory.social]),
    const Affirmation(id: 'social_4', text: 'I am a good listener and make others feel valued.', categories: [AffirmationCategory.social]),
    const Affirmation(id: 'social_5', text: 'My presence brings joy and light to those around me.', categories: [AffirmationCategory.social]),
    const Affirmation(id: 'social_6', text: 'I attract supportive and uplifting people into my life.', categories: [AffirmationCategory.social]),
    const Affirmation(id: 'social_7', text: 'I am comfortable being myself in any social situation.', categories: [AffirmationCategory.social]),
    const Affirmation(id: 'social_8', text: 'My friendships are deep, genuine, and filled with trust.', categories: [AffirmationCategory.social]),
    
    // Money affirmations
    const Affirmation(id: 'money_1', text: 'I am a magnet for prosperity and financial abundance.', categories: [AffirmationCategory.money]),
    const Affirmation(id: 'money_2', text: 'Money flows to me easily from multiple sources.', categories: [AffirmationCategory.money]),
    const Affirmation(id: 'money_3', text: 'I am worthy of wealth and financial freedom.', categories: [AffirmationCategory.money]),
    const Affirmation(id: 'money_4', text: 'My income grows steadily, and I manage it wisely.', categories: [AffirmationCategory.money]),
    const Affirmation(id: 'money_5', text: 'I release all limiting beliefs about money and success.', categories: [AffirmationCategory.money]),
    const Affirmation(id: 'money_6', text: 'Opportunities for abundance surround me everywhere I go.', categories: [AffirmationCategory.money]),
    const Affirmation(id: 'money_7', text: 'I create value in the world and am rewarded generously.', categories: [AffirmationCategory.money]),
    const Affirmation(id: 'money_8', text: 'Financial success is my birthright and I claim it now.', categories: [AffirmationCategory.money]),
  ];

  static final List<String> _dailyThemes = [
    'Today, I embrace new beginnings with courage.',
    'I am worthy of all the good coming my way.',
    'My potential is limitless and ever-expanding.',
    'I choose joy and gratitude in every moment.',
    'I am exactly where I need to be right now.',
    'Today is full of possibilities and promise.',
    'I release what no longer serves me with grace.',
    'My inner peace is my greatest strength.',
    'I trust the journey and welcome growth.',
    'I am loved, supported, and guided always.',
    'Every challenge is an opportunity to shine.',
    'I radiate positivity and attract abundance.',
    'My dreams are valid and worth pursuing.',
    'I honor my feelings and treat myself kindly.',
    'Today I take one step closer to my goals.',
  ];

  static final List<String> _microBoosts = [
    'You\'ve got this.',
    'One moment at a time.',
    'Progress over perfection.',
    'Breathe. You\'re doing great.',
    'Small steps lead to big wins.',
  ];

  String getRandomMessage({AffirmationCategory? category, int? seed}) {
    final messages = [..._dailyThemes, ..._microBoosts];
    if (messages.isEmpty) return _dailyThemes.first;
    var effectiveSeed = seed ?? DateTime.now().millisecondsSinceEpoch;
    if (category != null) {
      effectiveSeed += category.index * 1000;
    }
    final random = _SeededRandom(effectiveSeed);
    return messages[random.nextInt(messages.length)];
  }

  List<Affirmation> getRandomPack({AffirmationCategory? category, int count = 8, int? seed}) {
    final pool = category != null
        ? _allAffirmations.where((a) => a.categories.contains(category)).toList()
        : List<Affirmation>.from(_allAffirmations);
    final effectiveSeed = seed ?? DateTime.now().millisecondsSinceEpoch;
    return _getShuffledPack(pool, effectiveSeed, count);
  }

  String getDailyTheme() {
    final now = DateTime.now();
    final daysSinceEpoch = now.difference(DateTime(2024, 1, 1)).inDays;
    return _dailyThemes[daysSinceEpoch % _dailyThemes.length];
  }

  List<Affirmation> getDailyPack({AffirmationCategory? category}) {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    
    final pool = category != null
        ? _allAffirmations.where((a) => a.categories.contains(category)).toList()
        : _allAffirmations;
    
    return _getShuffledPack(pool, seed, 5);
  }

  List<Affirmation> getExtraPack({AffirmationCategory? category}) {
    final now = DateTime.now();
    final seed = now.millisecondsSinceEpoch;
    
    final pool = category != null
        ? _allAffirmations.where((a) => a.categories.contains(category)).toList()
        : _allAffirmations;
    
    return _getShuffledPack(pool, seed, 5);
  }

  List<Affirmation> getSessionPack(AffirmationCategory category) {
    final now = DateTime.now();
    final seed = now.millisecondsSinceEpoch;
    final pool = _allAffirmations.where((a) => a.categories.contains(category)).toList();
    return _getShuffledPack(pool, seed, 5);
  }

  /// Builds a session pack using affirmations from any of the provided categories.
  /// If the list is empty, falls back to the full pool.
  List<Affirmation> getSessionPackForCategories(List<AffirmationCategory> categories) {
    final now = DateTime.now();
    final seed = now.millisecondsSinceEpoch;
    List<Affirmation> pool;
    if (categories.isEmpty) {
      pool = List.from(_allAffirmations);
    } else {
      final set = categories.toSet();
      pool = _allAffirmations.where((a) => a.categories.any(set.contains)).toList();
    }
    return _getShuffledPack(pool, seed, 5);
  }

  List<Affirmation> searchAffirmations(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return _allAffirmations
        .where((a) => a.text.toLowerCase().contains(lowerQuery))
        .toList();
  }

  List<Affirmation> getAffirmationsByCategory(AffirmationCategory category) =>
      _allAffirmations.where((a) => a.categories.contains(category)).toList();

  List<Affirmation> _getShuffledPack(List<Affirmation> pool, int seed, int count) {
    if (pool.isEmpty) return [];
    final List<Affirmation> shuffled = List.from(pool);
    final random = _SeededRandom(seed);
    
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    
    return shuffled.take(count).toList();
  }
}

class _SeededRandom {
  int _seed;
  
  _SeededRandom(this._seed);
  
  int nextInt(int max) {
    _seed = ((_seed * 1103515245) + 12345) & 0x7fffffff;
    return _seed % max;
  }
}
