import 'package:finlink_mobile/features/auth/register/register_screen.dart';
import 'package:finlink_mobile/features/home/home_screen.dart';
import 'package:finlink_mobile/main.dart';
import 'package:finlink_mobile/features/auth/login/login_screen.dart';
import 'package:finlink_mobile/utils/named_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: NamedRoutes.register.path,
      name: NamedRoutes.register.name,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: NamedRoutes.home.path,
      name: NamedRoutes.home.name,
      builder: (context, state) => const HomeScreen(),
    )
  ],
);