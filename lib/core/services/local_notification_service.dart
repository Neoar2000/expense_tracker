import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._internal();

  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  static LocalNotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _plugin.initialize(settings);

    final androidGranted = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        true;
    final iosGranted = await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;

    debugPrint(
      '[Notifications] Android granted: $androidGranted, iOS granted: $iosGranted',
    );

    _initialized = true;
  }

  Future<void> showBudgetAlert({
    required String title,
    required String body,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    debugPrint('[Notifications] Showing local alert: $title - $body');

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}

final localNotificationServiceProvider =
    Provider<LocalNotificationService>((_) => LocalNotificationService.instance);
