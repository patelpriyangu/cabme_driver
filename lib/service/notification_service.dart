import 'dart:convert';
import 'dart:developer';

import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:uniqcars_driver/controller/home_controller.dart';
import 'package:uniqcars_driver/page/chats_screen/conversation_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
  log("BackGround Message :: ${message.messageId}");
}

// Channel IDs
const String _channelNewRide = 'new_ride_requests';
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
          onDidReceiveNotificationResponse: (payload) {});

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
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      FirebaseMessaging.onBackgroundMessage(
          (message) => firebaseMessageBackgroundHandle(message));
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("::::::::::::onMessage:::::::::::::::::");
      if (message.notification != null) {
        log(message.notification.toString());
        display(message);
      }
      if (message.data['tag'] == 'scheduled_ride_unassigned' ||
          message.data['tag'] == 'scheduled_ride' ||
          message.data['tag'] == 'scheduled_ride_cancelled') {
        try {
          Get.find<HomeController>().getUpcomingRides();
        } catch (_) {}
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      log("::::::::::::onMessageOpenedApp:::::::::::::::::");
      if (message.notification != null) {
        if (message.data['status'] == "done") {
          await Get.to(ConversationScreen(), arguments: {
            'receiverId': int.parse(
                json.decode(message.data['message'])['senderId'].toString()),
            'orderId': int.parse(
                json.decode(message.data['message'])['orderId'].toString()),
            'receiverName':
                json.decode(message.data['message'])['senderName'].toString(),
            'receiverPhoto':
                json.decode(message.data['message'])['senderPhoto'].toString(),
          });
        }
      }
    });
    log("::::::::::::Permission authorized:::::::::::::::::");
    await FirebaseMessaging.instance.subscribeToTopic("uniqcars_driver");
  }

  static Future<String?>? getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    return token;
  }

  void display(RemoteMessage message) async {
    log('Got a message whilst in the foreground!');
    log('Message data: ${message.notification!.body.toString()}');

    final tag = message.data['tag'] ?? '';

    // Play sound based on notification type
    try {
      if (tag == 'ridenewrider' || tag == 'ridenewriderparcel') {
        // New ride request — loud ringtone to grab attention
        FlutterRingtonePlayer().playRingtone(
          looping: false,
          volume: 1.0,
          asAlarm: false,
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
