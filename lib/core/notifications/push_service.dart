import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/data/notifications_repository.dart';

/// Ported from ilm-ai-mobile's utils/pushNotifications.ts, with one
/// deliberate behavior change (signed off on during planning): registers a
/// real FCM/APNs token instead of an Expo push token, since a plain Flutter
/// app has no equivalent of Expo's push-token relay. The backend's
/// send_push() (services/push.py) dispatches to FCM directly for these
/// tokens, added as an additive branch alongside the existing Expo path.
///
/// Firebase.initializeApp() is wrapped in try/catch -- until the user adds
/// real Firebase project files (android/app/google-services.json,
/// ios/Runner/GoogleService-Info.plist), this silently no-ops instead of
/// crashing the app, mirroring the RN app's "EAS not linked -> return null"
/// pattern for the same reason (push setup requires external credentials
/// this environment doesn't have).
class PushService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[push] Firebase not configured, push notifications disabled: $e');
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));

    const channel = AndroidNotificationChannel('default', 'Default', importance: Importance.high);
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(android: AndroidNotificationDetails('default', 'Default', importance: Importance.high)),
      );
    });
  }

  /// Requests permission and returns a real FCM token, or null if Firebase
  /// isn't configured, the platform is a simulator, or permission is denied.
  static Future<String?> _registerForPushNotifications() async {
    await _ensureInitialized();
    if (Firebase.apps.isEmpty) return null;

    if (!kIsWeb) {
      final deviceInfo = DeviceInfoPlugin();
      final isPhysicalDevice = defaultTargetPlatform == TargetPlatform.android
          ? (await deviceInfo.androidInfo).isPhysicalDevice
          : defaultTargetPlatform == TargetPlatform.iOS
              ? (await deviceInfo.iosInfo).isPhysicalDevice
              : true;
      if (!isPhysicalDevice) return null;
    }

    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return null;

    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('[push] Failed to get FCM token: $e');
      return null;
    }
  }

  /// Registers the current device's push token with the backend. Safe to
  /// call multiple times; guards against redundant registration should be
  /// applied by the caller (see the one-shot `_registered` ref in
  /// RootNavigator-equivalent code), matching the RN app's useRef guard.
  static Future<void> registerWithBackend(Ref ref, int userId) async {
    final token = await _registerForPushNotifications();
    if (token == null) return;
    try {
      await ref.read(notificationsRepositoryProvider).registerToken(userId: userId, token: token);
    } catch (e) {
      debugPrint('[push] Failed to register token with backend: $e');
    }
  }
}
