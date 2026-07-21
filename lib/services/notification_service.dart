import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages local push notifications for Bloom & Deliver.
/// All copy is written in Lily's voice as per Tier 7 spec.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  // ── Notification IDs ───────────────────────────────────────────────────────

  static const int _idDailyReminder = 1;
  static const int _idFlashSale = 2;
  static const int _idWiltWarning = 3;

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings =
          InitializationSettings(android: android, iOS: ios);

      await _plugin.initialize(settings);
      _ready = true;
    } catch (e) {
      // Graceful: notifications simply won't fire if init fails
      debugPrint('NotificationService init failed: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await android?.requestNotificationsPermission() ?? false;
      return granted;
    } catch (_) {
      return false;
    }
  }

  // ── Channel helper ─────────────────────────────────────────────────────────

  AndroidNotificationDetails get _androidDetails =>
      const AndroidNotificationDetails(
        'bloom_deliver_channel',
        'Bloom & Deliver',
        channelDescription: 'Game reminders and alerts',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

  NotificationDetails get _details =>
      NotificationDetails(android: _androidDetails);

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Schedule a daily "come back to your shop" reminder at [hour]:[minute].
  Future<void> scheduleDailyReminder({int hour = 10, int minute = 0}) async {
    if (!_ready) return;
    try {
      await _plugin.periodicallyShow(
        _idDailyReminder,
        '🌸 Lily is waiting for you!',
        'New customers are lining up outside the shop. Come take their orders!',
        RepeatInterval.daily,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('scheduleDailyReminder failed: $e');
    }
  }

  /// Show an immediate flash sale notification.
  Future<void> showFlashSaleNotification(String flowerName) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        _idFlashSale,
        '🔥 Flash Sale — 30% off $flowerName!',
        'Lily says: "Stock up now — this deal disappears in 2 hours!"',
        _details,
      );
    } catch (e) {
      debugPrint('showFlashSaleNotification failed: $e');
    }
  }

  /// Show a wilt warning for a specific flower.
  Future<void> showWiltWarning(String flowerName) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        _idWiltWarning,
        '⚠️ Your $flowerName are wilting!',
        'Lily says: "Use them in a bouquet today or they\'ll be gone by morning!"',
        _details,
      );
    } catch (e) {
      debugPrint('showWiltWarning failed: $e');
    }
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  // ── Opt-in daily reminder ────────────────────────────────────────────────
  //
  // Strictly opt-in and off by default: nothing is scheduled and no Android
  // permission is requested until the player enables it. A cozy game must never
  // nag, so this is the only recurring notification and the player owns it.

  static const _prefKeyReminder = 'daily_reminder_enabled';

  /// Whether the player has opted into the daily reminder (persisted).
  Future<bool> isDailyReminderEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKeyReminder) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Turn the daily reminder on or off. On enable, best-effort requests the
  /// Android 13+ notification permission (iOS is handled at init) and schedules
  /// the reminder; on disable, cancels it. The player's choice is persisted.
  /// All underlying calls fail silently, so this never throws.
  Future<void> setDailyReminder(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyReminder, enabled);
    } catch (_) {
      // Preference persistence is best-effort.
    }
    if (enabled) {
      await requestPermissions();
      await scheduleDailyReminder();
    } else {
      await cancelAll();
    }
  }
}
