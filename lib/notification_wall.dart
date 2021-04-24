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
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//
// const AndroidNotificationChannel channel = AndroidNotificationChannel(
//   'high_importance_channel', // id
//   'High Importance Notifications', // title
//   'This channel is used for important notifications.', // description
//   importance: Importance.high,
// );

/// This future will handle background notifications
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// The wall widget,
class NotificationWall extends StatefulWidget {
  /// called everytime a new notification arrives
  final Function(RemoteMessage? message)
      onNewNotificationCallback; // I will  push a new route with this widget
  /// Called eerytime a new token is set
  final Function(String token) onSetTokenCallback;

  /// Returned while setting up the Firebase
  final Widget
      onSettingUpWall; // I will return this while setting up notifications wall
  ///Returned after setup is done
  final Widget
      childWidget; // I will return this after proper setting up notification wall
  ///Obtional list of topics to subscribe
  final List<String>? topicsToSubscribe;

  NotificationWall(
      {required this.onNewNotificationCallback,
      required this.childWidget,
      required this.onSetTokenCallback,
      required this.onSettingUpWall,
      this.topicsToSubscribe});

  @override
  _NotificationWallState createState() => _NotificationWallState();
}

class _NotificationWallState extends State<NotificationWall> {
  /// Return onSettingUpWall while false
  bool isReady = false;
  Stream<String>? _tokenStream;

  ///Helper to set and propagate token
  void setToken(String token) {
    widget.onSetTokenCallback(token);
  }

  ///Set up Firebase settings
  Future<void> onInitWall() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    //
    // if (defaultTargetPlatform == TargetPlatform.android) {
    //   await flutterLocalNotificationsPlugin
    //       .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    //       ?.createNotificationChannel(channel);
    // }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    onInitWall()
        .then((value) => {
              FirebaseMessaging.instance
                  .requestPermission(
                    announcement: true,
                    carPlay: true,
                    criticalAlert: true,
                  )
                  .then((NotificationSettings settings) => {
                        _tokenStream =
                            FirebaseMessaging.instance.onTokenRefresh,
                        _tokenStream?.listen(setToken),
                        FirebaseMessaging.onMessage
                            .listen((RemoteMessage? message) {
                          widget.onNewNotificationCallback(message);

                          // RemoteNotification? notification = message?.notification;
                          // AndroidNotification? android = message?.notification?.android;
                          // if (notification != null && android != null) {
                          //   flutterLocalNotificationsPlugin.show(
                          //       notification.hashCode,
                          //       notification.title,
                          //       notification.body,
                          //       NotificationDetails(
                          //         android: AndroidNotificationDetails(
                          //           channel.id,
                          //           channel.name,
                          //           channel.description,
                          //           icon: 'launch_background',
                          //         ),
                          //       ));
                          // }
                        }),
                        FirebaseMessaging.onMessageOpenedApp
                            .listen((RemoteMessage? message) {
                          if (message != null) {
                            widget.onNewNotificationCallback(message);
                          }
                        }),
                        FirebaseMessaging.instance
                            .getInitialMessage()
                            .then((RemoteMessage? message) {
                          if (message != null) {
                            widget.onNewNotificationCallback(message);
                          }
                          // Navigator.pushNamed(context, '/message', arguments: MessageArguments(message, true));
                        }),
                        FirebaseMessaging.instance.getToken().then((token) => {
                              setToken(token ?? ""),
                              widget.topicsToSubscribe?.forEach((topic) {
                                FirebaseMessaging.instance
                                    .subscribeToTopic(topic);
                              }),
                              setState(() {
                                isReady = true;
                              })
                            })
                      })
            })
        .then((_) => {
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
      return widget.onSettingUpWall;
    }
  }
}
