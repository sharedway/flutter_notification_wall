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

/// The wall widget,
class NotificationWall extends StatefulWidget {
  /// called everytime a new notification arrives
  final Function(RemoteMessage? message) onNewNotificationCallback; // I will  push a new route with this widget
  /// Called eerytime a new token is set
  final Function(String token) onSetTokenCallback;
  final FirebaseOptions firebaseOptions;

  /// Called once after setting up
  final Function() onSetupIsDoneCallback;

  /// Returned while setting up the Firebase
  final Widget onSettingUpWall; // I will return this while setting up notifications wall
  ///Returned after setup is done
  final Widget childWidget; // I will return this after proper setting up notification wall
  ///Obtional list of topics to subscribe
  final List<String>? topicsToSubscribe;

  NotificationWall(
      {required this.onNewNotificationCallback,
      required this.childWidget,
      required this.firebaseOptions,
      required this.onSetTokenCallback,
      required this.onSettingUpWall,
      required this.onSetupIsDoneCallback,
      this.topicsToSubscribe});

  @override
  _NotificationWallState createState() => _NotificationWallState();
}

class _NotificationWallState extends State<NotificationWall> {
  /// Return onSettingUpWall while false
  bool isReady = false;
  Stream<String>? _tokenStream;

  // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();

  ///Helper to set and bubble up  token
  void setToken(String token) {
    widget.onSetTokenCallback(token);
  }

  ///Helper to set and bubble up new nessages
  Future<void> onBackgroundNotificationCallBack(RemoteMessage? message) async {
    await Firebase.initializeApp(options: widget.firebaseOptions);

    /// lets check if the message is null before bubble up
    onNotificationCallBack(message);
  }
  //
  // static const AndroidNotificationChannel androidChannel =
  //     AndroidNotificationChannel(
  //   'high_importance_channel', // id
  //   'High Importance Notifications', // title
  //   'This channel is used for important notifications.', // description
  //   importance: Importance.high,
  // );

  ///Helper to set and bubble up new nessages
  void onNotificationCallBack(RemoteMessage? message) {
    if (message != null) {
      widget.onNewNotificationCallback(message);

      //
      // if (message.notification?.android != null) {
      //   flutterLocalNotificationsPlugin.show(
      //       message.notification?.hashCode ?? 0,
      //       message.notification?.title,
      //       message.notification?.body,
      //       NotificationDetails(
      //         android: AndroidNotificationDetails(
      //           androidChannel.id,
      //           androidChannel.name,
      //           androidChannel.description,
      //           // TODO add a proper drawable resource to android, for now using
      //           //      one that already exists in example app.
      //           icon: 'launch_background',
      //         ),
      //       ));
      // }
    }

    /// lets check if the message is null before bubble up
  }

  ///Set up Firebase settings
  Future<void> onInitWall() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(onBackgroundNotificationCallBack);

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

    /// keep the loading state (isReady=false) while setting up
    /// FirebaseMessaging
    onInitWall()
        .then((_) => {
              FirebaseMessaging.instance
                  .requestPermission(
                    announcement: true,
                    carPlay: true,
                    criticalAlert: true,
                  )
                  .then((NotificationSettings settings) => {
                        _tokenStream = FirebaseMessaging.instance.onTokenRefresh,
                        _tokenStream?.listen(setToken),
                        FirebaseMessaging.onMessage.listen((RemoteMessage? message) {
                          onNotificationCallBack(message);
                        }),
                        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) {
                          onNotificationCallBack(message);
                        }),
                        FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
                          onNotificationCallBack(message);
                        }),
                        FirebaseMessaging.instance.getToken().then((token) => {
                              setToken(token ?? ""),
                              widget.topicsToSubscribe?.forEach((topic) {
                                FirebaseMessaging.instance.subscribeToTopic(topic);
                              }),
                              // setState(() {
                              //   isReady = true;
                              // })
                            })
                      })
            })
        .then((_) => {
              /// this property name will change later to isDone, we need to
              /// handle a failling initialization of  FirebaseMessaging...
              setState(() {
                isReady = true;
              })
            })
        .then((_) => widget.onSetupIsDoneCallback());
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
