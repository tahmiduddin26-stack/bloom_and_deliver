import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

Future<void> openSettingsScreen(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = !AudioService.instance.isMuted;
  bool _reminderEnabled = false;
  bool _savingReminder = false;

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    final enabled = await NotificationService.instance.isDailyReminderEnabled();
    if (mounted) setState(() => _reminderEnabled = enabled);
  }

  Future<void> _setSound(bool enabled) async {
    setState(() => _soundEnabled = enabled);
    await AudioService.instance.setMuted(!enabled);
    if (mounted) {
      setState(() => _soundEnabled = !AudioService.instance.isMuted);
    }
  }

  Future<void> _setReminder(bool enabled) async {
    if (_savingReminder) return;
    setState(() {
      _savingReminder = true;
      _reminderEnabled = enabled;
    });
    await NotificationService.instance.setDailyReminder(enabled);
    final saved = await NotificationService.instance.isDailyReminderEnabled();
    if (mounted) {
      setState(() {
        _reminderEnabled = saved;
        _savingReminder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      backgroundColor: AppColors.gardenGreenDark,
      foregroundColor: Colors.white,
      title: Text(
        'Settings',
        style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFDDEBC5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cartoonInk, width: 2),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                color: AppColors.gardenGreenDark,
                size: 34,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Make your flower shop feel just right.',
                  style: GoogleFonts.nunito(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gardenGreenDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _SettingsHeading('How it feels'),
        _SettingsToggle(
          icon: Icons.music_note_rounded,
          title: 'Sound & music',
          subtitle: 'Shop ambience, flower taps and reward chimes',
          value: _soundEnabled,
          onChanged: _setSound,
          color: const Color(0xFFFFE4AE),
        ),
        _SettingsToggle(
          icon: Icons.notifications_active_rounded,
          title: 'Daily reminder',
          subtitle: 'One gentle nudge each day; off until you choose it',
          value: _reminderEnabled,
          onChanged: _savingReminder ? null : _setReminder,
          color: const Color(0xFFFFDDE1),
        ),
        const SizedBox(height: 22),
        _SettingsHeading('Good to know'),
        _InfoCard(
          icon: Icons.save_rounded,
          title: 'Your progress saves automatically',
          detail: 'Your garden journey is stored on this device.',
        ),
        _InfoCard(
          icon: Icons.text_fields_rounded,
          title: 'Comfortable reading',
          detail: 'Use your phone’s text-size setting to make labels larger.',
        ),
        _InfoCard(
          icon: Icons.local_florist_rounded,
          title: 'Bloom & Deliver',
          detail: 'A cheerful little flower shop, one bouquet at a time.',
        ),
      ],
    ),
  );
}

class _SettingsHeading extends StatelessWidget {
  final String title;
  const _SettingsHeading(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: AppColors.gardenGreenDark,
      ),
    ),
  );
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color color;
  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.cartoonInk, width: 2),
    ),
    child: SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.gardenGreenDark,
      secondary: Icon(icon, color: AppColors.gardenGreenDark, size: 29),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: AppColors.gardenGreenDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.brownDark,
        ),
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.warmWhite,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.cartoonInk, width: 1.5),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.gardenGreenDark),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  color: AppColors.gardenGreenDark,
                ),
              ),
              Text(
                detail,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brownDark,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
