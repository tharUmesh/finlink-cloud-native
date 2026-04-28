import 'package:finlink_mobile/features/auth/login/login_viewmodel.dart';
import 'package:finlink_mobile/features/auth/register/register_viewmodel.dart';
import 'package:finlink_mobile/services/auth_service.dart';
import 'package:get_it/get_it.dart';
GetIt servicelocator = GetIt.instance;

void setupServiceLocator() {
  servicelocator.registerLazySingleton<AuthService>(() => AuthService());
  servicelocator.registerFactory<LoginViewmodel>(() => LoginViewmodel(servicelocator<AuthService>()));
  servicelocator.registerFactory<RegisterViewmodel>(() => RegisterViewmodel(servicelocator<AuthService>()));
}