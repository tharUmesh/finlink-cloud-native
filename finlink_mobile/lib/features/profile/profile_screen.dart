import 'package:finlink_mobile/features/base_screen.dart';
import 'package:finlink_mobile/features/profile/profile_viewmodel.dart';
import 'package:finlink_mobile/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends BaseScreen {
	const ProfileScreen({super.key});

	@override
	Widget mainContent(BuildContext context) {
		return ChangeNotifierProvider(
			create: (_) => servicelocator<ProfileViewmodel>()..loadProfile(),
			child: Consumer<ProfileViewmodel>(
				builder: (context, viewmodel, child) {
					return SafeArea(
						child: ListView(
							padding: const EdgeInsets.all(16),
							children: [
								const Text(
									'My Profile',
									style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
								),
								const SizedBox(height: 16),
								if (viewmodel.isLoading)
									const Center(
										child: Padding(
											padding: EdgeInsets.symmetric(vertical: 24),
											child: CircularProgressIndicator(),
										),
									),
								if (viewmodel.errorMessage != null)
									_CenteredMessageCard(
										message: viewmodel.errorMessage!,
										onRetry: viewmodel.loadProfile,
									),
								_ProfileHeaderCard(viewmodel: viewmodel),
								const SizedBox(height: 16),
								_SectionCard(
									title: 'Account Details',
									children: [
										_DetailTile(label: 'Email', value: viewmodel.email),
										_DetailTile(label: 'Phone', value: viewmodel.phone),
										_DetailTile(label: 'NIC', value: viewmodel.nic),
										_DetailTile(label: 'Tier', value: viewmodel.accountTier),
										ListTile(
											contentPadding: EdgeInsets.zero,
											leading: const Icon(Icons.edit_outlined),
											title: const Text('Edit profile'),
											trailing: const Icon(Icons.chevron_right),
											onTap: () => viewmodel.showFeatureMessage(
												context,
												'Edit profile',
											),
										),
									],
								),
								const SizedBox(height: 12),
								_SectionCard(
									title: 'Preferences',
									children: [
										SwitchListTile.adaptive(
											contentPadding: EdgeInsets.zero,
											title: const Text('App notifications'),
											subtitle:
													const Text('Receive transaction and security alerts'),
											value: viewmodel.notificationsEnabled,
											onChanged: viewmodel.toggleNotifications,
										),
										SwitchListTile.adaptive(
											contentPadding: EdgeInsets.zero,
											title: const Text('Biometric login'),
											subtitle:
													const Text('Use fingerprint/face for quick access'),
											value: viewmodel.biometricEnabled,
											onChanged: viewmodel.toggleBiometric,
										),
									],
								),
								const SizedBox(height: 12),
								_SectionCard(
									title: 'Support',
									children: [
										ListTile(
											contentPadding: EdgeInsets.zero,
											leading: const Icon(Icons.lock_outline),
											title: const Text('Privacy policy'),
											trailing: const Icon(Icons.chevron_right),
											onTap: () => viewmodel.showFeatureMessage(
												context,
												'Privacy policy',
											),
										),
										ListTile(
											contentPadding: EdgeInsets.zero,
											leading: const Icon(Icons.help_outline),
											title: const Text('Help center'),
											trailing: const Icon(Icons.chevron_right),
											onTap: () => viewmodel.showFeatureMessage(
												context,
												'Help center',
											),
										),
									],
								),
								const SizedBox(height: 16),
								SizedBox(
									height: 48,
									child: OutlinedButton.icon(
										onPressed: () => viewmodel.handleLogout(context),
										icon: const Icon(Icons.logout),
										label: const Text('Logout'),
									),
								),
								const SizedBox(height: 8),
							],
						),
					);
				},
			),
		);
	}
}

class _ProfileHeaderCard extends StatelessWidget {
	const _ProfileHeaderCard({required this.viewmodel});

	final ProfileViewmodel viewmodel;

	@override
	Widget build(BuildContext context) {
		final colorScheme = Theme.of(context).colorScheme;

		return Card(
			elevation: 0,
			color: colorScheme.primaryContainer.withValues(alpha: 0.65),
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Row(
					children: [
						CircleAvatar(
							radius: 28,
							backgroundColor: colorScheme.primary,
							child: Text(
								viewmodel.initials,
								style: TextStyle(
									color: colorScheme.onPrimary,
									fontWeight: FontWeight.bold,
									fontSize: 20,
								),
							),
						),
						const SizedBox(width: 12),
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										viewmodel.fullName,
										style: const TextStyle(
											fontSize: 18,
											fontWeight: FontWeight.w700,
										),
									),
									const SizedBox(height: 4),
									const Text('FinLink Member'),
								],
							),
						),
					],
				),
			),
		);
	}
}

class _SectionCard extends StatelessWidget {
	const _SectionCard({required this.title, required this.children});

	final String title;
	final List<Widget> children;

	@override
	Widget build(BuildContext context) {
		return Card(
			elevation: 0,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
			child: Padding(
				padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(
							title,
							style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
						),
						const SizedBox(height: 8),
						...children,
					],
				),
			),
		);
	}
}

class _DetailTile extends StatelessWidget {
	const _DetailTile({required this.label, required this.value});

	final String label;
	final String value;

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.symmetric(vertical: 8),
			child: Row(
				children: [
					Text(
						'$label:',
						style: TextStyle(
							color: Colors.grey.shade700,
							fontWeight: FontWeight.w600,
						),
					),
					const SizedBox(width: 8),
					Expanded(
						child: Text(
							value,
							textAlign: TextAlign.end,
							style: const TextStyle(fontWeight: FontWeight.w500),
						),
					),
				],
			),
		);
	}
}

class _CenteredMessageCard extends StatelessWidget {
	const _CenteredMessageCard({required this.message, required this.onRetry});

	final String message;
	final VoidCallback onRetry;

	@override
	Widget build(BuildContext context) {
		return Card(
			elevation: 0,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					children: [
						Text(
							message,
							textAlign: TextAlign.center,
							style: TextStyle(color: Colors.grey.shade700),
						),
						const SizedBox(height: 12),
						SizedBox(
							height: 40,
							child: OutlinedButton.icon(
								onPressed: onRetry,
								icon: const Icon(Icons.refresh),
								label: const Text('Retry'),
							),
						),
					],
				),
			),
		);
	}
}
