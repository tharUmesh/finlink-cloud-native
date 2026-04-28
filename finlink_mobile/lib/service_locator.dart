import 'package:finlink_mobile/features/auth/login/login_viewmodel.dart';
import 'package:finlink_mobile/features/auth/register/register_viewmodel.dart';
import 'package:finlink_mobile/features/profile/profile_viewmodel.dart';
import 'package:finlink_mobile/services/auth/auth_service.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:finlink_mobile/services/user/user_service.dart';
import 'package:finlink_mobile/services/wallet/wallet_service.dart';
import 'package:get_it/get_it.dart';
GetIt servicelocator = GetIt.instance;

void setupServiceLocator() {
  servicelocator.registerLazySingleton<AuthService>(() => AuthService());
  servicelocator.registerLazySingleton<AuthSession>(() => AuthSession());
  servicelocator.registerLazySingleton<UserService>(
    () => UserService(servicelocator<AuthSession>()),
  );
  servicelocator.registerLazySingleton<WalletService>(
    () => WalletService(servicelocator<AuthSession>()),
  );
  servicelocator.registerFactory<LoginViewmodel>(
    () => LoginViewmodel(
      servicelocator<AuthService>(),
      servicelocator<AuthSession>(),
    ),
  );
  servicelocator.registerFactory<RegisterViewmodel>(
    () => RegisterViewmodel(servicelocator<AuthService>()),
  );
  servicelocator.registerFactory<ProfileViewmodel>(
    () => ProfileViewmodel(
      servicelocator<AuthSession>(),
      servicelocator<UserService>(),
    ),
  );
}