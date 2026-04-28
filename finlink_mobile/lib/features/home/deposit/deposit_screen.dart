import 'package:finlink_mobile/features/home/deposit/deposit_viewmodel.dart';
import 'package:finlink_mobile/features/home/widgets/success_widget.dart';
import 'package:finlink_mobile/service_locator.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:finlink_mobile/services/transaction/transaction_service.dart';
import 'package:finlink_mobile/services/transaction/transaction_refresh_notifier.dart';
import 'package:finlink_mobile/services/wallet/wallet_service.dart';
import 'package:finlink_mobile/utils/named_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DepositScreen extends StatelessWidget {
	const DepositScreen({super.key});

	Future<void> _handleDeposit(
		BuildContext context,
		DepositViewmodel viewmodel,
	) async {
		final didSubmit = await viewmodel.submit(context);
		if (!didSubmit || !context.mounted) {
			return;
		}

		await showDialog<void>(
			context: context,
			barrierDismissible: false,
			builder: (dialogContext) {
				return SuccessDialog(
					title: 'Deposit Successful',
					message: 'Funds have been added to your wallet.',
					buttonText: 'Go Home',
					onPressed: () {
						viewmodel.clear();
						Navigator.of(dialogContext).pop();
						context.goNamed(NamedRoutes.home.name);
					},
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		return ChangeNotifierProvider(
			create: (_) => DepositViewmodel(
				servicelocator<AuthSession>(),
				servicelocator<WalletService>(),
				servicelocator<TransactionService>(),
				servicelocator<TransactionRefreshNotifier>(),
			),
			child: Consumer<DepositViewmodel>(
				builder: (context, viewmodel, child) {
					return WillPopScope(
						onWillPop: () async {
							viewmodel.clear();
							return true;
						},
						child: Scaffold(
							appBar: AppBar(
								title: const Text('Deposit'),
								centerTitle: false,
								leading: IconButton(
									onPressed: () => viewmodel.close(context),
									icon: const Icon(Icons.arrow_back_ios_new_rounded),
								),
							),
							body: SafeArea(
								child: Padding(
									padding: const EdgeInsets.all(16),
									child: Form(
										key: viewmodel.depositFormKey,
										child: Column(
											children: [
												Expanded(
													child: ListView(
														children: [
															const SizedBox(height: 8),
															TextFormField(
																controller: viewmodel.walletIdController,
																readOnly: true,
																decoration: InputDecoration(
																	labelText: 'Wallet ID',
																	border: const OutlineInputBorder(),
																	suffixIcon: IconButton(
																		onPressed: viewmodel.isLoadingWalletId
																				? null
																				: viewmodel.refreshWalletId,
																		icon: viewmodel.isLoadingWalletId
																				? const SizedBox(
																						width: 18,
																						height: 18,
																						child: CircularProgressIndicator(
																							strokeWidth: 2,
																						),
																					)
																				: const Icon(Icons.refresh_rounded),
																		tooltip: 'Refresh',
																	),
																),
																validator: viewmodel.validateWalletId,
															),
															const SizedBox(height: 12),
															TextFormField(
																controller: viewmodel.amountController,
																keyboardType:
																		const TextInputType.numberWithOptions(
																	decimal: true,
																),
																inputFormatters: [
																	FilteringTextInputFormatter.allow(
																		RegExp(r'^\d*\.?\d{0,2}'),
																	),
																],
																decoration: const InputDecoration(
																	labelText: 'Amount',
																	hintText: 'Enter amount',
																	border: OutlineInputBorder(),
																),
																validator: viewmodel.validateAmount,
															),
															if (viewmodel.errorMessage != null &&
																	viewmodel.errorMessage!.isNotEmpty) ...[
																const SizedBox(height: 10),
																Text(
																	viewmodel.errorMessage!,
																	style: const TextStyle(
																		color: Color(0xFFB91C1C),
																		fontSize: 13,
																	),
																),
															],
														],
													),
												),
												const SizedBox(height: 12),
												SizedBox(
													width: double.infinity,
													height: 48,
													child: ElevatedButton(
														onPressed: viewmodel.isSubmitting
																? null
																: () => _handleDeposit(context, viewmodel),
														child: viewmodel.isSubmitting
																? const SizedBox(
																		width: 20,
																		height: 20,
																		child: CircularProgressIndicator(
																			strokeWidth: 2,
																			valueColor:
																					AlwaysStoppedAnimation<Color>(
																				Colors.white,
																			),
																		),
																	)
																: const Text('Deposit'),
													),
												),
											],
										),
									),
								),
							),
						),
					);
				},
			),
		);
	}
}
