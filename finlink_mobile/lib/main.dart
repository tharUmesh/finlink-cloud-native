import 'package:finlink_mobile/features/auth/login/login_viewmodel.dart';
import 'package:finlink_mobile/navigation_routes.dart';
import 'package:finlink_mobile/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => servicelocator<LoginViewmodel>()),
    ],
    child: MaterialApp.router(
      title: 'FinLink',
      debugShowCheckedModeBanner: false,
      routerConfig: router,

    ),);
    
  }
}

