/*
 * *
 *  * Created by Lauro Cesar de Oliveira <lauro@hostcert.com.br> on 4/15/21 10:32 AM
 *  * Copyright (c) 2021 . All rights reserved.
 *  * Last modified 4/15/21 10:15 AM
 */

library notification_wall;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  'This channel is used for important notifications.', // description
  importance: Importance.high,
);

class NotificationWall extends StatefulWidget {
  final Widget onNewNotification; // I will  push a new route with this widget
  Widget? onSettingUpWall; // I will return this while setting up notifications wall
  final Widget childWidget; // I will return this after proper setting up notification wall

  NotificationWall({required this.onNewNotification, required this.childWidget, this.onSettingUpWall});

  @override
  _NotificationWallState createState() => _NotificationWallState();
}

class _NotificationWallState extends State<NotificationWall> {
  bool isReady = false;

  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // await Firebase.initializeApp();
    print('Handling a background message ${message.messageId}');
  }

  Future<void> onInitWall() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    if (defaultTargetPlatform == TargetPlatform.android) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    onInitWall().then((value) => {
          FirebaseMessaging.onMessage.listen((RemoteMessage? message) {
            RemoteNotification? notification = message?.notification;
            AndroidNotification? android = message?.notification?.android;
            if (notification != null && android != null) {
              flutterLocalNotificationsPlugin.show(
                  notification.hashCode,
                  notification.title,
                  notification.body,
                  NotificationDetails(
                    android: AndroidNotificationDetails(
                      channel.id,
                      channel.name,
                      channel.description,
                      icon: 'launch_background',
                    ),
                  ));
            }
          }),
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) {
            print('A new onMessageOpenedApp event was published!');
          }),
          FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
            print(message);
            // Navigator.pushNamed(context, '/message', arguments: MessageArguments(message, true));
          }),
          setState(() {
            isReady = true;
          })
        });
  }

  @override
  Widget build(BuildContext context) {
    if (isReady) {
      return widget.childWidget;
    } else {
      return widget.onSettingUpWall ??
          Scaffold(
            body: Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
    }
  }
}
