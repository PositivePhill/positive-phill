import 'dart:convert';
import 'dart:io' if (dart.library.html) 'package:positive_phill/io_stub.dart' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:positive_phill/providers/theme_provider.dart';
import 'package:positive_phill/providers/user_provider.dart';
import 'package:positive_phill/services/haptics_service.dart';
import 'package:positive_phill/services/notifications_service.dart';
import 'package:positive_phill/platform/background_image.dart';
import 'package:positive_phill/services/storage_service.dart';
import 'package:positive_phill/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  bool _notificationsEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  String _versionLabel = 'Version';
  String? _customBgPath;
  String? _customBgWeb;
  bool _textBacklightEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
    _loadVersion();
    _loadCustomBackground();
    _loadTextBacklight();
  }

  Future<void> _loadTextBacklight() async {
    final enabled = await _storage.getTextBacklightEnabled();
    if (mounted) {
      setState(() => _textBacklightEnabled = enabled);
    }
  }

  Future<void> _loadCustomBackground() async {
    final bgPath = await _storage.getCustomBackgroundPath();
    final bgWeb = await _storage.getCustomBackgroundWeb();
    if (mounted) {
      setState(() {
        _customBgPath = bgPath;
        _customBgWeb = bgWeb;
      });
    }
  }

  Future<void> _pickBackgroundImage() async {
    HapticsService.feedback(FeedbackType.selection);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 70,
      );
      if (picked == null || !mounted) return;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        final b64 = base64Encode(bytes);
        if (b64.length > 4 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image too large')),
            );
          }
          return;
        }
        await _storage.setCustomBackgroundPath(null);
        await _storage.setCustomBackgroundWeb(b64);
        if (mounted) {
          setState(() {
            _customBgPath = null;
            _customBgWeb = b64;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Background updated')),
          );
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final ext = picked.path.contains('.') ? '.${picked.path.split('.').last}' : '.jpg';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newPath = path.join(dir.path, 'bg_$timestamp$ext');
        await io.File(picked.path).copy(newPath);
        await _storage.setCustomBackgroundWeb(null);
        await _storage.setCustomBackgroundPath(newPath);
        if (mounted) {
          setState(() {
            _customBgPath = newPath;
            _customBgWeb = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Background updated')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not set background: $e')),
        );
      }
    }
  }

  Future<void> _openRepositionDialog() async {
    HapticsService.feedback(FeedbackType.selection);
    final align = await _storage.getCustomBackgroundAlignment();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => RepositionDialog(
        bgPath: _customBgPath,
        bgWeb: _customBgWeb,
        initialAlignment: align,
        onSave: (a) async {
          await _storage.setCustomBackgroundAlignment(a);
        },
      ),
    );
  }

  Future<void> _clearBackground() async {
    HapticsService.feedback(FeedbackType.selection);
    try {
      await _storage.clearCustomBackground();
      if (mounted) {
        setState(() {
          _customBgPath = null;
          _customBgWeb = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Background cleared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not clear background: $e')),
        );
      }
    }
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _versionLabel = 'Version ${info.version} (${info.buildNumber})');
  }

  Future<void> _openExternalUrl(String url) async {
    try {
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  Future<void> _contactSupport() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final subject = Uri.encodeComponent('Positive Phill Support');
      final body = Uri.encodeComponent(
        'Please describe your issue above this line.\n\n---\n'
        'App: Positive Phill\n'
        'Version: ${info.version} (${info.buildNumber})\n'
        'Platform: ${defaultTargetPlatform.name}\n'
      );
      final uri = Uri.parse('mailto:possummattern@gmail.com?subject=$subject&body=$body');
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client')),
        );
      }
    }
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await _storage.getNotificationsEnabled();
    final hour = await _storage.getReminderHour();
    final minute = await _storage.getReminderMinute();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _reminderTime = TimeOfDay(hour: hour, minute: minute);
      });
    }
  }

  Future<void> _onNotificationsToggle(bool value) async {
    HapticsService.feedback(FeedbackType.selection);
    try {
      if (value) {
        await NotificationsService.instance.init();
        await _storage.setNotificationsEnabled(true);
        await NotificationsService.instance.scheduleDailyAffirmation(time: _reminderTime);
        if (mounted) {
          setState(() => _notificationsEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daily reminders enabled')),
          );
        }
      } else {
        await NotificationsService.instance.cancelDailyAffirmation();
        await _storage.setNotificationsEnabled(false);
        if (mounted) {
          setState(() => _notificationsEnabled = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daily reminders disabled')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update reminders: $e')),
        );
      }
    }
  }

  Future<void> _onReminderTimeTap() async {
    HapticsService.feedback(FeedbackType.selection);
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && mounted) {
      setState(() => _reminderTime = picked);
      await _storage.setReminderTime(picked.hour, picked.minute);
      if (_notificationsEnabled) {
        await NotificationsService.instance.scheduleDailyAffirmation(time: picked);
      }
    }
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reset Progress'),
          content: const Text(
            'Are you sure you want to reset all your progress? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await context.read<UserProvider>().resetProgress();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Progress reset successfully')),
                  );
                }
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: colorScheme.onSurface)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: AppSpacing.horizontalLg,
            child: Text(
              'Appearance',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Text Backlight'),
            subtitle: const Text('Improves readability on bright backgrounds'),
            value: _textBacklightEnabled,
            onChanged: (value) async {
              HapticsService.feedback(FeedbackType.selection);
              await _storage.setTextBacklightEnabled(value);
              if (mounted) setState(() => _textBacklightEnabled = value);
            },
            secondary: Icon(Icons.text_fields, color: colorScheme.primary, size: 24),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle dark theme'),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              HapticsService.feedback(FeedbackType.selection);
              themeProvider.setThemeMode(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
            secondary: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          ListTile(
            leading: Icon(Icons.wallpaper, color: colorScheme.primary),
            title: const Text('Inspirational Board'),
            subtitle: const Text('Choose a background image'),
            trailing: (_customBgPath != null || _customBgWeb != null)
                ? IconButton(
                    icon: Icon(Icons.close, color: colorScheme.primary),
                    onPressed: _clearBackground,
                  )
                : null,
            onTap: _pickBackgroundImage,
          ),
          if (_customBgPath != null || _customBgWeb != null)
            ListTile(
              leading: Icon(Icons.center_focus_strong, color: colorScheme.primary),
              title: const Text('Reposition Background'),
              subtitle: const Text('Adjust how the image is framed'),
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: _openRepositionDialog,
            ),
          const Divider(),
          Padding(
            padding: AppSpacing.horizontalLg,
            child: Text(
              'Notifications',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Daily Reminders'),
            subtitle: const Text('Get notified for daily sessions'),
            value: _notificationsEnabled,
            onChanged: _onNotificationsToggle,
            secondary: Icon(Icons.notifications, color: colorScheme.primary),
          ),
          ListTile(
            leading: Icon(Icons.schedule, color: colorScheme.primary),
            title: const Text('Reminder Time'),
            subtitle: Text(_reminderTime.format(context)),
            trailing: const Icon(Icons.edit, size: 20),
            onTap: _onReminderTimeTap,
          ),
          const Divider(),
          Padding(
            padding: AppSpacing.horizontalLg,
            child: Text(
              'Progress',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.refresh, color: colorScheme.error),
            title: const Text('Reset Progress'),
            subtitle: const Text('Clear all XP, levels, and favorites'),
            onTap: () {
              HapticsService.feedback(FeedbackType.warning);
              _showResetDialog(context);
            },
          ),
          const Divider(),
          Padding(
            padding: AppSpacing.horizontalLg,
            child: Text(
              'About',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.info, color: colorScheme.primary),
            title: const Text('Possum Mattern Studios'),
            subtitle: Text(_versionLabel),
          ),
          ListTile(
            leading: Icon(Icons.language, color: colorScheme.primary),
            title: const Text('Website'),
            subtitle: const Text('Visit our website'),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () {
              HapticsService.feedback(FeedbackType.selection);
              _openExternalUrl('https://positivephill.github.io/positive-phill/index.html');
            },
          ),
          ListTile(
            leading: Icon(Icons.support, color: colorScheme.primary),
            title: const Text('Support'),
            subtitle: const Text('Get help and support'),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () {
              HapticsService.feedback(FeedbackType.selection);
              _contactSupport();
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip, color: colorScheme.primary),
            title: const Text('Privacy Policy'),
            subtitle: const Text('Read our privacy policy'),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () {
              HapticsService.feedback(FeedbackType.selection);
              _openExternalUrl('https://positivephill.github.io/positive-phill/privacy.html');
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class RepositionDialog extends StatefulWidget {
  final String? bgPath;
  final String? bgWeb;
  final Alignment initialAlignment;
  final Future<void> Function(Alignment) onSave;

  const RepositionDialog({
    super.key,
    required this.bgPath,
    required this.bgWeb,
    required this.initialAlignment,
    required this.onSave,
  });

  @override
  State<RepositionDialog> createState() => _RepositionDialogState();
}

class _RepositionDialogState extends State<RepositionDialog> {
  late double _x;
  late double _y;

  @override
  void initState() {
    super.initState();
    _x = widget.initialAlignment.x;
    _y = widget.initialAlignment.y;
  }

  Alignment get _alignment => Alignment(_x.clamp(-1.0, 1.0), _y.clamp(-1.0, 1.0));

  Widget _buildPreview() {
    final align = _alignment;
    if (kIsWeb && widget.bgWeb != null && widget.bgWeb!.isNotEmpty) {
      try {
        final bytes = base64Decode(widget.bgWeb!);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          alignment: align,
        );
      } catch (_) {
        return const Center(child: Text('Preview unavailable'));
      }
    }
    if (!kIsWeb && widget.bgPath != null && widget.bgPath!.isNotEmpty) {
      return BackgroundImageBuilder.build(widget.bgPath!, alignment: align);
    }
    return const Center(child: Text('Preview unavailable'));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Reposition Background'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildPreview(),
              ),
            ),
            const SizedBox(height: 24),
            Text('Move Left / Right', style: textTheme.titleSmall),
            Slider(
              value: _x,
              min: -1.0,
              max: 1.0,
              onChanged: (v) => setState(() => _x = v),
            ),
            Text('Move Up / Down', style: textTheme.titleSmall),
            Slider(
              value: _y,
              min: -1.0,
              max: 1.0,
              onChanged: (v) => setState(() => _y = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _x = 0;
              _y = 0;
            });
          },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await widget.onSave(_alignment);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
