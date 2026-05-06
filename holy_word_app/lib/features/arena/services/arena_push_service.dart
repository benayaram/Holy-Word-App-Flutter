import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/arena_api_client.dart';

/// Manages FCM token registration, foreground/background notification handling,
/// and local notification display for Bible Arena.
class ArenaPushService {
  static final ArenaPushService _instance = ArenaPushService._();
  factory ArenaPushService() => _instance;
  ArenaPushService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifs = FlutterLocalNotificationsPlugin();

  // Callback for handling notification taps (set by the app)
  void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Initialize push notification service
  Future<void> initialize({ArenaApiClient? apiClient}) async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // Initialize local notifications for foreground display
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifs.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'bible_arena',
      'Bible Arena',
      description: 'Battle challenges, tournament updates, and sermon quizzes',
      importance: Importance.high,
      playSound: true,
    );
    await _localNotifs
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Get and register FCM token
    final token = await _messaging.getToken();
    if (token != null && apiClient != null) {
      try {
        await apiClient.updateFcmToken(token);
        debugPrint('FCM token registered: ${token.substring(0, 20)}...');
      } catch (e) {
        debugPrint('FCM token registration failed: $e');
      }
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      if (apiClient != null) {
        try {
          await apiClient.updateFcmToken(newToken);
        } catch (_) {}
      }
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/terminated message tap handler
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Check if app was launched from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  /// Handle foreground messages by showing a local notification
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifs.show(
      notification.hashCode,
      notification.title ?? 'Bible Arena',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bible_arena', 'Bible Arena',
          channelDescription: 'Battle challenges and updates',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFe94560),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['type'] ?? '',
    );
  }

  /// Handle notification tap (from background/terminated)
  void _handleMessageTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    onNotificationTap?.call(message.data);
  }

  /// Handle local notification response tap
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      onNotificationTap?.call({'type': response.payload});
    }
  }

  /// Subscribe to a topic (e.g., church-specific notifications)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}
