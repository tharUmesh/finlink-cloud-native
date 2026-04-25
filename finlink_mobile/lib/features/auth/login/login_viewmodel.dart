import 'package:finlink_mobile/utils/named_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginViewmodel extends ChangeNotifier {
	final formKey = GlobalKey<FormState>();
	final emailController = TextEditingController();
	final passwordController = TextEditingController();

	String? validateEmail(String? value) {
		if (value == null || value.trim().isEmpty) {
			return 'Please enter your email';
		}
		if (!value.contains('@')) {
			return 'Enter a valid email';
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

	void handleLogin() {
		if (formKey.currentState?.validate() ?? false) {
			// Add login logic here.
		}
	}

	void navigateToRegister(BuildContext context) {
		context.go(NamedRoutes.register.path);
	}

	@override
	void dispose() {
		emailController.dispose();
		passwordController.dispose();
		super.dispose();
	}
}