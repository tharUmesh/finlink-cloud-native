import 'package:finlink_mobile/features/base_viewmodel.dart';
import 'package:finlink_mobile/models/user/user_profile_models.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:finlink_mobile/services/user/user_service.dart';
import 'package:finlink_mobile/utils/named_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileViewmodel extends BaseViewmodel {
	ProfileViewmodel(this._authSession, this._userService);

	final AuthSession _authSession;
	final UserService _userService;

	UserProfile? _profile;
	bool _isLoading = false;
	String? _errorMessage;

	bool _notificationsEnabled = true;
	bool _biometricEnabled = false;

	UserProfile? get profile => _profile;
	bool get isLoading => _isLoading;
	String? get errorMessage => _errorMessage;

	String get fullName =>
			_profile?.fullName ?? _authSession.user?.name ?? 'FinLink Member';
	String get email => _authSession.user?.email ?? 'Not provided';
	String get phone => _profile?.phoneNumber ?? _authSession.user?.phone ?? '—';
	String get nic => _profile?.nationalId ?? _authSession.user?.nic ?? '—';
	String get accountTier => _mapRoleToTier(_profile?.role ?? _authSession.user?.role);

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

	Future<void> loadProfile() async {
		if (_isLoading) {
			return;
		}
		if (!_authSession.isAuthenticated) {
			_errorMessage = 'Please login to view your profile.';
			notifyListeners();
			return;
		}

		_isLoading = true;
		_errorMessage = null;
		notifyListeners();

		try {
			_profile = await _userService.getProfile();
		} on UserServiceException catch (error) {
			_errorMessage = error.message;
		} catch (_) {
			_errorMessage = 'Unable to load profile right now.';
		} finally {
			_isLoading = false;
			notifyListeners();
		}
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
			_authSession.clear();
			context.go(NamedRoutes.login.path);
		}
	}

	String _mapRoleToTier(String? role) {
		switch (role) {
			case 'admin':
				return 'Admin';
			case 'lender':
				return 'Lender';
			case 'user':
				return 'Standard';
			default:
				return 'Standard';
		}
	}
}
