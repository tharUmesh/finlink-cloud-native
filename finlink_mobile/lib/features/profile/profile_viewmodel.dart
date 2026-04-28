import 'package:finlink_mobile/features/base_viewmodel.dart';
import 'package:finlink_mobile/utils/named_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileViewmodel extends BaseViewmodel {
	final String fullName = 'Nimal Perera';
	final String email = 'nimal.perera@finlink.app';
	final String phone = '+94 77 123 4567';
	final String nic = '981234567V';
	final String accountTier = 'Premium';

	bool _notificationsEnabled = true;
	bool _biometricEnabled = false;

	bool get notificationsEnabled => _notificationsEnabled;
	bool get biometricEnabled => _biometricEnabled;
	String get initials {
		final parts = fullName.trim().split(RegExp(r'\s+'));
		if (parts.isEmpty) {
			return 'U';
		}
		if (parts.length == 1) {
			return parts.first.characters.first.toUpperCase();
		}
		return (parts.first.characters.first + parts.last.characters.first)
				.toUpperCase();
	}

	void toggleNotifications(bool value) {
		_notificationsEnabled = value;
		notifyListeners();
	}

	void toggleBiometric(bool value) {
		_biometricEnabled = value;
		notifyListeners();
	}

	void showFeatureMessage(BuildContext context, String featureName) {
		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(content: Text('$featureName will be available soon.')),
		);
	}

	Future<void> handleLogout(BuildContext context) async {
		final shouldLogout = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Logout'),
				content: const Text('Are you sure you want to logout?'),
				actions: [
					TextButton(
						onPressed: () => Navigator.of(context).pop(false),
						child: const Text('Cancel'),
					),
					FilledButton(
						onPressed: () => Navigator.of(context).pop(true),
						child: const Text('Logout'),
					),
				],
			),
		);

		if (shouldLogout == true) {
			context.go(NamedRoutes.login.path);
		}
	}
}
