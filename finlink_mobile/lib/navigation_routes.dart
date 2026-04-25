import 'package:finlink_mobile/features/auth/register/register_screen.dart';
import 'package:finlink_mobile/features/home/home_screen.dart';
import 'package:finlink_mobile/features/home/receive/receive_screen.dart';
import 'package:finlink_mobile/features/home/qr_scanner/qr_scanner.dart';
import 'package:finlink_mobile/features/home/withdraw/withdraw_screen.dart';
import 'package:finlink_mobile/main.dart';
import 'package:finlink_mobile/features/auth/login/login_screen.dart';
import 'package:finlink_mobile/utils/named_routes.dart';
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
    ),
    GoRoute(
      path: NamedRoutes.receive.path,
      name: NamedRoutes.receive.name,
      builder: (context, state) => const ReceiveScreen(),
    ),
    GoRoute(
      path: NamedRoutes.qrScanner.path,
      name: NamedRoutes.qrScanner.name,
      builder: (context, state) => const QrScannerScreen(),
    ),
    GoRoute(
      path: NamedRoutes.withdraw.path,
      name: NamedRoutes.withdraw.name,
      builder: (context, state) => const WithdrawScreen(),
    )
  ],
);