import 'dart:async';

import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:six_cash/features/language/controllers/localization_controller.dart';
import 'package:six_cash/features/setting/controllers/theme_controller.dart';
import 'package:six_cash/helper/notification_helper.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/theme/dark_theme.dart';
import 'package:six_cash/theme/light_theme.dart';
import 'package:six_cash/util/app_constants.dart';
import 'package:six_cash/util/messages.dart';

import 'helper/get_di.dart' as di;
import 'services/fcm_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  await Firebase.initializeApp();

  if (GetPlatform.isAndroid) {
    await FirebaseMessaging.instance.requestPermission();
  }

  // ⭐ مزامنة FCM تلقائياً عند تجديد token من Firebase
  FcmService.listenToRefresh();

  ///firebase crashlytics

  cameras = await availableCameras();

  Map<String, Map<String, String>> languages = await di.init();

  int? orderID;
  // NotificationBody? body;
  try {
    final RemoteMessage? remoteMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (remoteMessage != null) {
      //body = NotificationHelper.convertNotification(remoteMessage.data);
    }
    await NotificationHelper.initialize(flutterLocalNotificationsPlugin);
    FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
  } catch (e) {
    if (kDebugMode) {
      print("");
    }
  }

  runApp(MyApp(languages: languages, orderID: orderID));
}

class MyApp extends StatelessWidget {
  final Map<String, Map<String, String>>? languages;
  final int? orderID;
  const MyApp({Key? key, required this.languages, required this.orderID})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return GetBuilder<LocalizationController>(
          builder: (localizeController) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1)),
              child: GetMaterialApp(
                navigatorObservers: [FlutterSmartDialog.observer],
                builder: FlutterSmartDialog.init(),
                title: AppConstants.appName,
                debugShowCheckedModeBanner: false,
                navigatorKey: Get.key,
                theme: themeController.darkTheme ? dark : light,
                locale: localizeController.locale,
                translations: Messages(languages: languages),
                fallbackLocale: const Locale('ar', 'SA'),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('ar', 'SA'),
                  Locale('en', 'US'),
                ],
                initialRoute: RouteHelper.getSplashRoute(),
                getPages: RouteHelper.routes,
                defaultTransition: Transition.topLevel,
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          },
        );
      },
    );
  }
}
