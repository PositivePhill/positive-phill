# Positive Phill - Architecture Plan

## App Overview
Professional Flutter mobile app for daily affirmations with gamification, local storage, and AdMob integration.

## Technical Stack
- **Framework**: Flutter (Material 3)
- **State Management**: Provider
- **Navigation**: go_router
- **Local Storage**: shared_preferences
- **Monetization**: google_mobile_ads
- **Web View**: webview_flutter

## Core Features

### 1. Daily Affirmation System
- **Daily Theme**: One theme line per day (deterministic based on date)
- **Daily Pack**: 5 affirmations per day (deterministic)
- **Extra Packs**: User can request more affirmations (rewarded ad unlock)
- **Categories**: Confidence, Calm, Gratitude, Discipline, Healing, Focus, Social, Money
- **Interactions**: Save/Favorite, Share, Carousel UI

### 2. Gamification
- **XP System**: +10 XP per favorite, +20 XP for daily session completion
- **Streak System**: Daily session tracking, resets after missed day
- **Level System**: Level up every 200 XP with progress bar
- **Celebrations**: Confetti animations for streak/level milestones

### 3. Daily Session Flow
- Guided 2-3 minute flow
- Category selection → Show 5 affirmations → Complete screen
- XP and streak rewards

### 4. WebView Integration
- Button to open YouImageFlip game
- WebView screen with AppBar

### 5. Monetization (AdMob)
- **Rewarded Ads**: User-initiated for extra affirmation packs
- **Interstitial Ads**: Optional, shown after daily session completion (max once)
- Test ad units in debug, production IDs for release

### 6. Settings
- Toggle dark/light mode
- Toggle notifications (UI ready)
- Reset progress
- About page with studio info

## Project Structure

```
lib/
├── main.dart                    # App entry point with Provider setup
├── theme.dart                   # Premium calm color palette
├── nav.dart                     # go_router configuration
├── models/
│   └── user_progress.dart       # XP, level, streak, favorites data
├── services/
│   ├── affirmations_service.dart   # Affirmation data and logic
│   ├── storage_service.dart        # shared_preferences wrapper
│   └── ads_service.dart            # AdMob integration
├── providers/
│   ├── theme_provider.dart         # Theme mode management
│   └── user_provider.dart          # User progress state
├── screens/
│   ├── home_screen.dart            # Main screen with pack carousel
│   ├── session_flow_screen.dart    # Guided daily session
│   ├── settings_screen.dart        # Settings and about
│   └── webview_screen.dart         # Game integration
└── widgets/
    ├── affirmation_card.dart       # Card with favorite/share
    ├── xp_progress_bar.dart        # Level progress indicator
    ├── streak_display.dart         # Streak counter
    └── celebration_animation.dart  # Confetti for milestones
```

## Data Models

### UserProgress
- xp: int
- level: int
- streak: int
- lastOpenDate: DateTime
- lastPackDate: DateTime
- extraPacksToday: int
- favorites: List<String> (affirmation IDs)

## Services

### AffirmationsService
- getDailyTheme(): String (deterministic by date)
- getDailyPack(): List<Affirmation> (5 affirmations)
- getExtraPack(category?): List<Affirmation>
- searchAffirmations(query): List<Affirmation>
- getAffirmationsByCategory(category): List<Affirmation>

### StorageService
- saveUserProgress(UserProgress)
- loadUserProgress(): UserProgress
- saveFavorites(List<String>)
- loadFavorites(): List<String>

### AdsService
- loadRewardedAd()
- showRewardedAd(onRewarded)
- loadInterstitialAd()
- showInterstitialAd()
- Test ad unit IDs for debug mode

## UI/UX Design

### Color Palette (Sophisticated Calm)
- Light Mode: Soft pastels (lavender, mint, cream) with white base
- Dark Mode: Deep navy/charcoal with muted accent colors
- Accent: Calming teal/blue for progress and CTAs

### Typography
- Primary: Inter (elegant, modern)
- Generous spacing between elements
- Large affirmation text for readability

### Animations
- Smooth carousel transitions
- Heart favorite animation
- Confetti on milestones
- Haptic feedback on key actions

## Implementation Steps

1. ✅ Setup dependencies (google_mobile_ads, shared_preferences, webview_flutter, confetti)
2. ✅ Update theme.dart with premium calm color palette
3. ✅ Create data models (UserProgress, Affirmation)
4. ✅ Implement services (AffirmationsService, StorageService, AdsService)
5. ✅ Create providers (ThemeProvider, UserProvider)
6. ✅ Build reusable widgets (AffirmationCard, XpProgressBar, StreakDisplay, Celebration)
7. ✅ Implement screens (Home, SessionFlow, Settings, WebView)
8. ✅ Setup navigation routes
9. ✅ Integrate AdMob with test IDs
10. ✅ Add Android/iOS permissions
11. ✅ Test and debug compilation

## Safety & Policy Compliance
- Rewarded ads are user-initiated only
- Clear "Watch ad to unlock" messaging
- Never block core features with ads
- Fallback to 1 free extra pack per day if ad fails
- Test ad units in debug builds
