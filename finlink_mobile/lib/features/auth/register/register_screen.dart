import 'package:finlink_mobile/features/auth/register/register_viewmodel.dart';
import 'package:finlink_mobile/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => servicelocator<RegisterViewmodel>(),
      child: Builder(
        builder: (context) {
          final viewmodel = context.watch<RegisterViewmodel>();

          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: viewmodel.formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          const Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Register to get started',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: viewmodel.nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              hintText: 'Enter your name',
                              border: OutlineInputBorder(),
                            ),
                            validator: viewmodel.validateName,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: viewmodel.phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Phone No',
                              hintText: 'Enter your phone number',
                              border: OutlineInputBorder(),
                            ),
                            validator: viewmodel.validatePhone,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: viewmodel.nicController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'NIC',
                              hintText: 'Enter your NIC',
                              border: OutlineInputBorder(),
                            ),
                            validator: viewmodel.validateNic,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: viewmodel.passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              border: OutlineInputBorder(),
                            ),
                            validator: viewmodel.validatePassword,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: viewmodel.isLoading
                                  ? null
                                  : () => viewmodel.handleRegister(context),
                              child: viewmodel.isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Register'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              TextButton(
                                onPressed: () => viewmodel.navigateToLogin(context),
                                child: const Text('Login'),
                              ),
                            ],
                          ),
                        ],
                      ),
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