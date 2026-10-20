import 'dart:async';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


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

  static StreamSubscription<String>? _tokenChanges;
  static String? _boundToken;
  static int _generation = 0;
  static Future<void> _pending = Future.value();

  static String? stop() {
    _generation++;
    _tokenChanges?.cancel();
    _tokenChanges = null;
    final token = _boundToken;
    _boundToken = null;
    return token;
  }

  static Future<void> unregister(Dio dio, int userId, String token, Options options) {
    _pending = _pending.then((_) async {
      try { await dio.post('/notifications/unregister-token', data: {'user_id': userId, 'token': token}, options: options); } catch (_) {}
    });
    return _pending;
  }

  /// Account scoped, with token rotation and stale async callback protection.
  static Future<void> registerWithBackend(Dio dio, int userId, bool Function() isCurrent) async {
    stop();
    final generation = _generation;
    Future<void> send(String token) {
      _pending = _pending.then((_) async {
        if (generation != _generation || !isCurrent()) return;
        _boundToken = token; // Logout can unbind an in-flight registration too.
        try {
          await dio.post('/notifications/register-token', data: {'user_id': userId, 'token': token});
        } catch (_) { /* Retry on login/resume or token rotation. */ }
      });
      return _pending;
    }
    try {
      if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) { return; }
      final token = await _registerForPushNotifications();
      if (generation != _generation || !isCurrent() || Firebase.apps.isEmpty) return;
      _tokenChanges = FirebaseMessaging.instance.onTokenRefresh.listen(send,
          onError: (Object _) {});
      if (token != null) await send(token);
    } catch (_) { /* Missing platform configuration cannot crash authentication. */ }
  }
}
