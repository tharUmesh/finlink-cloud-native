import 'package:finlink_mobile/features/base_viewmodel.dart';
import 'package:finlink_mobile/models/auth_models.dart';
import 'package:finlink_mobile/services/auth_service.dart';
import 'package:finlink_mobile/utils/named_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class LoginViewmodel extends BaseViewmodel {
	LoginViewmodel(this._authService);

	final AuthService _authService;
	final formKey = GlobalKey<FormState>();
	final phoneController = TextEditingController();
	final passwordController = TextEditingController();

	bool _isLoading = false;
	String? _errorMessage;

	bool get isLoading => _isLoading;
	String? get errorMessage => _errorMessage;

	String? validatePhoneNumber(String? value) {
		if (value == null || value.trim().isEmpty) {
			return 'Please enter your phone number';
		}
		if (value.trim().length < 10) {
			return 'Enter a valid phone number';
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

	Future<void> handleLogin(BuildContext context) async {
		if (!(formKey.currentState?.validate() ?? false)) {
			return;
		}

		_isLoading = true;
		_errorMessage = null;
		notifyListeners();

		try {
			await _authService.login(
				LoginRequest(
					phoneNumber: phoneController.text.trim(),
					password: passwordController.text,
				),
			);
			if (!context.mounted) {
				return;
			}
			context.pushNamed(NamedRoutes.home.name);
		} on AuthException catch (error) {
			_errorMessage = error.message;
			if (context.mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text(error.message)),
				);
			}
		} catch (_) {
			_errorMessage = 'Unable to login right now.';
			if (context.mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Unable to login right now.')),
				);
			}
		} finally {
			_isLoading = false;
			notifyListeners();
		}
	}

	void navigateToRegister(BuildContext context) {
		context.go(NamedRoutes.register.path);
	}

	@override
	void dispose() {
		phoneController.dispose();
		passwordController.dispose();
		super.dispose();
	}
}