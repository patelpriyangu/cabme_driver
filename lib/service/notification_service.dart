import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:uniqcars_driver/controller/home_controller.dart';
import 'package:uniqcars_driver/firebase_options.dart';
import 'package:uniqcars_driver/page/chats_screen/conversation_screen.dart';
import 'package:uniqcars_driver/page/dashboard_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
  log("BackGround Message :: ${message.messageId}");
  // FCM automatically shows notification for messages with a notification payload.
  // For data-only messages (no notification field), we manually show a local
  // notification so the driver still gets sound/vibration in background/killed state.
  if (message.notification == null && message.data.isNotEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(const InitializationSettings(android: initSettings));
    await plugin.show(
      0,
      message.data['title'] ?? 'New Ride Request',
      message.data['body'] ?? 'A new ride is available',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'new_ride_requests_v2',
          'New Ride Requests',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          sound: RawResourceAndroidNotificationSound('new_ride_alert'),
        ),
      ),
    );
  }
}

// Channel IDs — bump version suffix when changing sound to force Android
// to recreate the channel (Android caches channel settings permanently).
const String _channelNewRide = 'new_ride_requests_v2';
const String _channelUpcoming = 'upcoming_rides';
const String _channelGeneral = 'general';

class NotificationService {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initInfo() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    var request = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (request.authorizationStatus == AuthorizationStatus.authorized ||
        request.authorizationStatus == AuthorizationStatus.provisional) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      var iosInitializationSettings = const DarwinInitializationSettings();
      final InitializationSettings initializationSettings =
          InitializationSettings(
              android: initializationSettingsAndroid,
              iOS: iosInitializationSettings);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onDidReceiveNotificationResponse:
              (NotificationResponse notificationResponse) async {
        final payload = notificationResponse.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            final tag = data['tag'] ?? '';
            if (tag == 'ridenewrider' || tag == 'ridenewriderparcel') {
              Get.offAll(() => DashboardScreen());
            }
          } catch (e) {
            log('Notification tap handler error: $e');
          }
        }
      });

      // Create notification channels
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelNewRide,
            'New Ride Requests',
            description: 'Alerts for new ride requests',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            sound: RawResourceAndroidNotificationSound('new_ride_alert'),
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelUpcoming,
            'Upcoming Rides',
            description: 'Notifications for upcoming scheduled rides',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelGeneral,
            'General',
            description: 'General notifications',
            importance: Importance.defaultImportance,
            playSound: true,
          ),
        );
      }

      setupInteractedMessage();
    }
  }

  Future<void> setupInteractedMessage() async {
    // Handle the case where the app was launched from a notification tap
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      log("::::::::::::initialMessage:::::::::::::::::");
      _handleNotificationTap(initialMessage);
    }

    // Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("::::::::::::onMessage:::::::::::::::::");
      if (message.notification != null) {
        log(message.notification.toString());
        display(message);
      }

      // Refresh ride data for ride-related notifications
      final tag = message.data['tag'] ?? '';
      if (tag == 'ridenewrider' || tag == 'ridenewriderparcel') {
        try {
          Get.find<HomeController>().getBooking();
        } catch (_) {}
      }
      if (tag == 'scheduled_ride_unassigned' ||
          tag == 'scheduled_ride' ||
          tag == 'scheduled_ride_cancelled') {
        try {
          Get.find<HomeController>().getUpcomingRides();
        } catch (_) {}
      }
    });

    // When the user taps on a notification while app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      log("::::::::::::onMessageOpenedApp:::::::::::::::::");
      _handleNotificationTap(message);
    });

    log("::::::::::::Permission authorized:::::::::::::::::");
    await FirebaseMessaging.instance.subscribeToTopic("uniqcars_driver");
  }

  void _handleNotificationTap(RemoteMessage message) {
    final tag = message.data['tag'] ?? '';

    if (tag == 'ridenewrider' || tag == 'ridenewriderparcel' ||
        tag == 'ridearrived' || tag == 'rideonride' || tag == 'ridecompleted') {
      // Navigate to home/dashboard and refresh ride data
      try {
        Get.find<HomeController>().getBooking();
      } catch (_) {}
      Get.offAll(() => DashboardScreen());
    } else if (message.data['status'] == "done") {
      // Chat message notification
      try {
        Get.to(ConversationScreen(), arguments: {
          'receiverId': int.parse(
              json.decode(message.data['message'])['senderId'].toString()),
          'orderId': int.parse(
              json.decode(message.data['message'])['orderId'].toString()),
          'receiverName':
              json.decode(message.data['message'])['senderName'].toString(),
          'receiverPhoto':
              json.decode(message.data['message'])['senderPhoto'].toString(),
        });
      } catch (e) {
        log('Notification tap handler error: $e');
      }
    }
  }

  static Future<String?>? getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    return token;
  }

  void display(RemoteMessage message) async {
    log('Got a message whilst in the foreground!');
    log('Message data: ${message.notification!.body.toString()}');

    final tag = message.data['tag'] ?? '';

    // Skip notifications for the driver's own actions — the driver already
    // sees the result in-app via Pusher, no need for a redundant FCM alert.
    const driverOwnActionTags = {
      'ridearrived',
      'rideonride',
      'rideconfirmed',
      'ridecompleted',
    };
    if (driverOwnActionTags.contains(tag)) {
      log('Skipping notification for driver own action: $tag');
      return;
    }

    // Play sound based on notification type
    try {
      if (tag == 'ridenewrider' || tag == 'ridenewriderparcel') {
        // New ride request — custom UniqCars alert sound
        FlutterRingtonePlayer().play(
          fromAsset: 'assets/sounds/new_ride_alert.wav',
          looping: false,
          volume: 1.0,
          asAlarm: true,
        );
      } else if (tag == 'scheduled_ride') {
        // New upcoming ride assigned
        FlutterRingtonePlayer().playNotification(
          looping: false,
          volume: 0.8,
          asAlarm: false,
        );
      } else if (tag == 'scheduled_ride_unassigned' ||
          tag == 'scheduled_ride_cancelled') {
        // Removed from / cancelled upcoming ride
        FlutterRingtonePlayer().playNotification(
          looping: false,
          volume: 0.8,
          asAlarm: false,
        );
      } else {
        FlutterRingtonePlayer().playNotification(
          looping: false,
          volume: 0.7,
          asAlarm: false,
        );
      }
    } catch (e) {
      log('Sound playback error: $e');
    }

    // Pick the right notification channel
    String channelId;
    String channelName;
    if (tag == 'ridenewrider' || tag == 'ridenewriderparcel') {
      channelId = _channelNewRide;
      channelName = 'New Ride Requests';
    } else if (tag == 'scheduled_ride' || tag == 'scheduled_ride_unassigned') {
      channelId = _channelUpcoming;
      channelName = 'Upcoming Rides';
    } else {
      channelId = _channelGeneral;
      channelName = 'General';
    }

    try {
      AndroidNotificationDetails notificationDetails =
          AndroidNotificationDetails(
        channelId,
        channelName,
        importance: channelId == _channelNewRide
            ? Importance.max
            : Importance.high,
        priority: channelId == _channelNewRide ? Priority.max : Priority.high,
        ticker: 'ticker',
        playSound: true,
        enableVibration: true,
        sound: channelId == _channelNewRide
            ? const RawResourceAndroidNotificationSound('new_ride_alert')
            : null,
      );
      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
              presentAlert: true, presentBadge: true, presentSound: true);
      NotificationDetails notificationDetailsBoth = NotificationDetails(
          android: notificationDetails, iOS: darwinNotificationDetails);
      await FlutterLocalNotificationsPlugin().show(
        0,
        message.notification!.title,
        message.notification!.body,
        notificationDetailsBoth,
        payload: jsonEncode(message.data),
      );
    } on Exception catch (e) {
      log(e.toString());
    }
  }
}
