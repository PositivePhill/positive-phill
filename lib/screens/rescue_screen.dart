import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:positive_phill/models/rescue_intent.dart';
import 'package:positive_phill/nav.dart';
import 'package:positive_phill/services/haptics_service.dart';
import 'package:positive_phill/theme.dart';
import 'package:positive_phill/widgets/intent_card.dart';

class RescueScreen extends StatelessWidget {
  const RescueScreen({super.key});

  static const List<RescueIntent> _intents = [
    RescueIntent.calm,
    RescueIntent.hype,
    RescueIntent.focus,
    RescueIntent.healing,
    RescueIntent.confidence,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reset moment',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'What do you need right now?',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Pick a gentle focus. Take your time.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ..._intents.map(
                    (intent) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: IntentCard(
                        intent: intent,
                        onTap: () {
                          HapticsService.feedback(FeedbackType.selection);
                          context.push(AppRoutes.rescueFlowPath(intent));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Positive Phill is for daily wellbeing support, not a substitute for professional care.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
