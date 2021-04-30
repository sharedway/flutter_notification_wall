# notification_wall

A statefull widget to initialize and handle Firebase messaging notifications.

## Getting Started

This widget handle new notifications;


``` 
import 'package:notification_wall/notification_wall.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter NotificationWall Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: NotificationWall(
          topicsToSubscribe: ["news", "updates"],

          /// New token arrived, do something...
          onSetTokenCallback: (String token) {},

          /// we finished setting up
          onSetupIsDoneCallback: () {},

          /// New RemoteMessage arrived, do something...
          onNewNotificationCallback: (RemoteMessage? message) {},

          /// to hide the returned widgets, just put the NotificationWall as
          /// child of an IndexedStack
          /// Show this widget while setting up
          onSettingUpWall: Scaffold(
            body: Container(
              child: Center(
                child: Text("Setting Up remotenotifications"),
              ),
            ),
          ),

          ///show this after setting up is done...
          childWidget: MyHomePage(title: 'Flutter Demo Home Page'),
        ));
  }
}

```

## TODO:

* code generation to setup Android gradle;
* automatic setup Ios .plist 