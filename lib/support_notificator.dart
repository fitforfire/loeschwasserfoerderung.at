import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:loeschwasserfoerderung/crypto.dart';
import 'package:loeschwasserfoerderung/support_dashboard.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

//Define Class BackgroundService
@pragma('vm:entry-point')
class BackgroundService {
  static final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  static final service = FlutterBackgroundService();
  static bool notificationSentToday = false;
  static DateTime? lastCheckDate;
  static DateTime? lastFailedAttemptTime;

  //Request the Notification Permission
  static Future<void> requestPopUpNotification() async {
    while (true) {
      PermissionStatus notificationPermission =
          await Permission.notification.request();
      if (notificationPermission.isGranted) {
        await initBackground();
        break;
      }
      await Future.delayed(Duration(seconds: 2));
    }
  }

  //Initialize BackgroundService
  static Future<void> initBackground() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'support_channel_loeschwasserfoerderung',
          channelName: 'Support Nachrichten',
          channelDescription: 'Loeschwasserfoerderung Supportnachrichten',
          defaultColor: Colors.grey,
          importance: NotificationImportance.High,
          ledColor: Colors.white,
        ),
      ],
    );

    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: (receivedNotification) async {
        if (receivedNotification.channelKey ==
            'support_channel_loeschwasserfoerderung') {
          runApp(MaterialApp(
            debugShowCheckedModeBanner: false,
            home: DashboardPage(),
          ));
        }
      },
    );

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        foregroundServiceTypes: [
          AndroidForegroundType.dataSync,
        ],
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        onBackground: onIosBackground,
        autoStart: true,
      ),
    );

    service.startService();
  }

  //Start BackgroundService
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    service.on("stopService").listen((event) {
      service.stopSelf();
    });

    Timer.periodic(Duration(minutes: 1), (timer) async {
      await checkForSupportMessage();
    });
  }

  //IOS BackgroundService
  static Future<bool> onIosBackground(ServiceInstance service) async {
    await checkForSupportMessage();
    return true;
  }

  //Look for the time & init looking for Supportmessage (EMail) and sending Notification
  static Future<void> checkForSupportMessage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("notification") ?? true) {  //TODO: Somehow always true, why?
      DateTime now = DateTime.now();

      if (lastCheckDate == null || now.day != lastCheckDate!.day) {
        notificationSentToday = false;
        lastCheckDate = now;
      }

      if (notificationSentToday) return;

      if (now.hour == 7 && now.minute == 0) {
        await trySendSupportMessage();
      }

      if (lastFailedAttemptTime != null &&
          now.isAfter(lastFailedAttemptTime!.add(Duration(minutes: 15)))) {
        await trySendSupportMessage();
      }
    }
  }

  //See if there is an open Supportmessage (EMail)
  static Future<void> trySendSupportMessage() async {
    String? username = await secureStorage.read(key: 'username');
    String? password = await secureStorage.read(key: 'password');

    if (username == null || password == null) {
      return;
    }

    if (kIsWeb) {
      await dotenv.load(fileName: "assets/config/.env_web");
    } else {
      await dotenv.load(fileName: "assets/config/.env");
    }

    final url =
        "https://xn--lschwasserfrderung-d3bk.at/api/checkForSupportMessages.php";

    try {
      final response = await http.post(
        Uri.parse(url),
        body: await Crypto.encrypt(
            json.encode({'username': username, 'password': password})),
      );

      if (response.statusCode == 200) {
        await sendNotification();
        notificationSentToday = true;
      } else if (response.statusCode == 404) {
        notificationSentToday = true;
      }
    } catch (ignored) {
      lastFailedAttemptTime = DateTime.now();
    }
  }

  //Send the Notification
  static Future<void> sendNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'support_channel_loeschwasserfoerderung',
        title: 'Löschwasserförderung Support',
        body: 'Es sind offene Supportnachrichten vorhanden',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  //Stop BackgroundService and disable notifications
  static Future<void> stopBackgroundService() async {
    // Stop the background service
    if (await service.isRunning()) {
      service.invoke('stopService');
    }

    // Cancel all notifications
    await AwesomeNotifications().cancelAll();

    // Reset notification flags
    notificationSentToday = false;
    lastCheckDate = null;
    lastFailedAttemptTime = null;
  }
}
