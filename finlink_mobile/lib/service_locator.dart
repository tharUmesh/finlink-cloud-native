import 'package:finlink_mobile/features/auth/login/login_viewmodel.dart';
import 'package:finlink_mobile/features/auth/register/register_viewmodel.dart';
import 'package:finlink_mobile/features/profile/profile_viewmodel.dart';
import 'package:finlink_mobile/services/auth/auth_service.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:finlink_mobile/services/cards/linked_cards_store.dart';
import 'package:finlink_mobile/services/loan/loan_service.dart';
import 'package:finlink_mobile/services/notification/notification_service.dart';
import 'package:finlink_mobile/services/transaction/transaction_service.dart';
import 'package:finlink_mobile/services/transaction/transaction_refresh_notifier.dart';
import 'package:finlink_mobile/services/user/user_service.dart';
import 'package:finlink_mobile/services/wallet/wallet_service.dart';
import 'package:get_it/get_it.dart';
GetIt servicelocator = GetIt.instance;

void setupServiceLocator() {
  servicelocator.registerLazySingleton<AuthService>(() => AuthService());
  servicelocator.registerLazySingleton<AuthSession>(() => AuthSession());
  if (!servicelocator.isRegistered<LinkedCardsStore>()) {
    servicelocator.registerSingleton<LinkedCardsStore>(LinkedCardsStore());
  }
  servicelocator.registerLazySingleton<UserService>(
    () => UserService(servicelocator<AuthSession>()),
  );
  servicelocator.registerLazySingleton<WalletService>(
    () => WalletService(servicelocator<AuthSession>()),
  );
  servicelocator.registerLazySingleton<TransactionService>(
    () => TransactionService(servicelocator<AuthSession>()),
  );
  servicelocator.registerLazySingleton<LoanService>(
    () => LoanService(servicelocator<AuthSession>()),
  );
  servicelocator.registerLazySingleton<TransactionRefreshNotifier>(
    () => TransactionRefreshNotifier(),
  );
  servicelocator.registerLazySingleton<NotificationService>(
    () => NotificationService(servicelocator<AuthSession>()),
  );
  servicelocator.registerFactory<LoginViewmodel>(
    () => LoginViewmodel(
      servicelocator<AuthService>(),
      servicelocator<AuthSession>(),
      servicelocator<WalletService>(),
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