import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint("Background notification received: ${message.messageId}");
  }
}

class FirebaseNotificationService {
  FirebaseNotificationService._();
  static final FirebaseNotificationService instance =
      FirebaseNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    try {
      // 1. طلب الصلاحيات لنظام Android 13+ و iOS
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        debugPrint('Notification permission status: ${settings.authorizationStatus}');
      }

      // 2. إعداد التنبيهات في المقدمة لـ iOS
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. تهيئة التنبيهات المحلية لعرض الإشعار عندما يكون التطبيق مفتوحاً
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (kDebugMode) {
            debugPrint("Notification clicked with payload: ${response.payload}");
          }
        },
      );

      // إنشاء قناة التنبيهات الافتراضية لنظام أندرويد
      const androidChannel = AndroidNotificationChannel(
        'buqsh_notifications',
        'إشعارات بُقش',
        description: 'قناة الإشعارات الأساسية لتطبيق بُقش',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // 4. استخراج رمز الجهاز (FCM Token)
      _fcmToken = await _fcm.getToken();
      if (kDebugMode) {
        debugPrint('FCM Token: $_fcmToken');
      }

      // مراقبة تجديد الرمز
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (kDebugMode) {
          debugPrint('FCM Token Refreshed: $_fcmToken');
        }
      });

      // 5. الاستماع للإشعارات أثناء فتح التطبيق (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint('Foreground Message: ${message.notification?.title}');
        }
        _showLocalNotification(message);
      });

      // 6. الاستماع للنقر على الإشعار من شريط التنبيهات
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint('Notification opened from system tray: ${message.data}');
        }
      });

      // إعداد معالج الإشعارات في الخلفية
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirebaseNotificationService initialization error: $e');
      }
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    final title = notification?.title ?? message.data['title'] ?? 'إشعار جديد';
    final body = notification?.body ?? message.data['body'] ?? '';

    const androidDetails = AndroidNotificationDetails(
      'buqsh_notifications',
      'إشعارات بُقش',
      channelDescription: 'قناة الإشعارات الأساسية لتطبيق بُقش',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      details,
      payload: message.data.toString(),
    );
  }
}
