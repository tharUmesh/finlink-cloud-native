import 'package:finlink_mobile/features/base_viewmodel.dart';
import 'package:finlink_mobile/models/auth/auth_models.dart';
import 'package:finlink_mobile/services/auth/auth_service.dart';
import 'package:finlink_mobile/utils/named_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class RegisterViewmodel extends BaseViewmodel {
	RegisterViewmodel(this._authService);

	final AuthService _authService;
	final formKey = GlobalKey<FormState>();
	final nameController = TextEditingController();
	final phoneController = TextEditingController();
	final nicController = TextEditingController();
	final passwordController = TextEditingController();

	bool _isLoading = false;
	String? _errorMessage;

	bool get isLoading => _isLoading;
	String? get errorMessage => _errorMessage;

	String? validateName(String? value) {
		if (value == null || value.trim().isEmpty) {
			return 'Please enter your name';
		}
		return null;
	}

	String? validatePhone(String? value) {
		if (value == null || value.trim().isEmpty) {
			return 'Please enter your phone number';
		}
		if (value.trim().length < 10) {
			return 'Enter a valid phone number';
		}
		return null;
	}

	String? validateNic(String? value) {
		if (value == null || value.trim().isEmpty) {
			return 'Please enter your NIC';
		}
		return null;
	}

	String? validatePassword(String? value) {
		if (value == null || value.isEmpty) {
			return 'Please enter your password';
		}
		if (value.length < 6) {
			return 'Password must be at least 6 characters';
		}
		return null;
	}

	Future<void> handleRegister(BuildContext context) async {
		if (!(formKey.currentState?.validate() ?? false)) {
			return;
		}

		_isLoading = true;
		_errorMessage = null;
		notifyListeners();

		try {
			await _authService.register(
				RegisterRequest(
					fullName: nameController.text.trim(),
					phoneNumber: phoneController.text.trim(),
					nationalId: nicController.text.trim(),
					password: passwordController.text,
				),
			);
			if (!context.mounted) {
				return;
			}
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Registration completed. Please login.')),
			);
			context.go(NamedRoutes.login.path);
		} on AuthException catch (error) {
			_errorMessage = error.message;
			if (context.mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text(error.message)),
				);
			}
		} catch (_) {
			_errorMessage = 'Unable to register right now.';
			if (context.mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Unable to register right now.')),
				);
			}
		} finally {
			_isLoading = false;
			notifyListeners();
		}
	}

	void navigateToLogin(BuildContext context) {
		context.go(NamedRoutes.login.path);
	}

	@override
	void dispose() {
		nameController.dispose();
		phoneController.dispose();
		nicController.dispose();
		passwordController.dispose();
		super.dispose();
	}
}