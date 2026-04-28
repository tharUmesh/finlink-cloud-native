import 'package:finlink_mobile/navigation_routes.dart';
import 'package:finlink_mobile/service_locator.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() {
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FinLink',
      debugShowCheckedModeBanner: false,
      routerConfig: router,

    );
    
  }
}

