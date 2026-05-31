import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'tenku_high_importance',
    'Tenku Notifications',
    description: 'Tenku messages, reactions, and alerts',
    importance: Importance.max,
    playSound: true,
  );

  Future<void> initialize(String userId) async {
    // Request permissions
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Initialize local notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotif.initialize(initSettings);

    await _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Save FCM token to Firestore
    final token = await _fcm.getToken();
    if (token != null) await _saveFcmToken(userId, token);

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((token) => _saveFcmToken(userId, token));

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) => _showLocalNotification(message));

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _handleNotificationTap(message));
  }

  Future<void> _saveFcmToken(String userId, String token) async {
    await _db.collection('users').doc(userId).update({'fcmToken': token});
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotif.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navigation handled by the app's router
    final data = message.data;
    if (data['route'] != null) {
      // TODO: Navigate to route
    }
  }

  // Save notification to Firestore
  Future<void> saveNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? imageUrl,
    String? actionId,
    String? actionRoute,
    Map<String, dynamic>? metadata,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'actionId': actionId,
      'actionRoute': actionRoute,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'metadata': metadata ?? {},
    });
  }

  // Stream notifications for a user
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => NotificationModel.fromFirestore(d)).toList());
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    final unread = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Stream unread count
  Stream<int> streamUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }
}

// Top-level background message handler (must be outside class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in main.dart
}
