import 'package:finlink_mobile/utils/named_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterViewmodel extends ChangeNotifier {
	final formKey = GlobalKey<FormState>();
	final nameController = TextEditingController();
	final emailController = TextEditingController();
	final phoneController = TextEditingController();
	final nicController = TextEditingController();
	final passwordController = TextEditingController();

	String? validateName(String? value) {
		if (value == null || value.trim().isEmpty) {
			return 'Please enter your name';
		}
		return null;
	}

	String? validateEmail(String? value) {
		if (value == null || value.trim().isEmpty) {
			return 'Please enter your email';
		}
		if (!value.contains('@')) {
			return 'Enter a valid email';
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

	void handleRegister() {
		if (formKey.currentState?.validate() ?? false) {
			// Add register logic here.
		}
	}

	void navigateToLogin(BuildContext context) {
		context.go(NamedRoutes.login.path);
	}

	@override
	void dispose() {
		nameController.dispose();
		emailController.dispose();
		phoneController.dispose();
		nicController.dispose();
		passwordController.dispose();
		super.dispose();
	}
}