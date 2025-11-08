import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService extends GetxService {
  static int _id = 0;
  static final FlutterLocalNotificationsPlugin _notificationInstance = FlutterLocalNotificationsPlugin();

  Future<NotificationService> init() async {
    await _notificationInstance.getNotificationAppLaunchDetails();

    // 創建 Android Notification Channel
    if (Platform.isAndroid) {
      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        'TownPass android notification id',
        'TownPass android notification channel name',
        description: 'TownPass 推送通知頻道',
        importance: Importance.max,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
      );

      await _notificationInstance
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    final InitializationSettings initializationSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
          // add action when notification clicked
        },
      ),
    );

    await _notificationInstance.initialize(initializationSettings);

    return this;
  }

  static Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      await _notificationInstance.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _notificationInstance.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  static Future<void> showNotification({String? title, String? content}) async {
    final int notificationId = _id++;
    await _notificationInstance.show(
      notificationId,
      title,
      content,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'TownPass android notification id',
          'TownPass android notification channel name',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
          playSound: true,
          // 確保每次都提醒，而不是只提醒一次
          setAsGroupSummary: false,
          autoCancel: true,
          // 每次都發出聲音和震動
          onlyAlertOnce: false,
          // 使用時間戳作為 tag 確保通知不會被合併
          tag: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
