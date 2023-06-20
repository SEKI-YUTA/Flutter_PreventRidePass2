import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prevent_ride_pass2/map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  // FlutterLocalNotificationsPlugin flp = FlutterLocalNotificationsPlugin();
  // const AndroidInitializationSettings initializationSettingsAndroid =
  //     AndroidInitializationSettings('location_target');
  // const DarwinInitializationSettings initializationSettingsDarwin =
  //     DarwinInitializationSettings(
  //   requestSoundPermission: false,
  //   requestBadgePermission: false,
  //   requestAlertPermission: false,
  // );
  // const InitializationSettings initializationSettings = InitializationSettings(
  //   android: initializationSettingsAndroid,
  //   iOS: initializationSettingsDarwin,
  // );
  // flp.initialize(
  //   initializationSettings,
  // );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true),
      home: const MapScreen(title: 'Flutter Demo Home Page'),
    );
  }
}
