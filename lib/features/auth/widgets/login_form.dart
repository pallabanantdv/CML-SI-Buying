import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    if (await auth.login(_username.text.trim(), _password.text)) {
      if (mounted) context.goNamed(RouteNames.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _username,
          label: 'Email or username',
          keyboardType: TextInputType.emailAddress,
          validator: (value) => Validators.required(value, 'Username'),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _password,
          label: 'Password',
          obscureText: true,
          validator: (value) => Validators.required(value, 'Password'),
        ),
        const SizedBox(height: 24),
        Consumer<AuthViewModel>(
          builder: (context, auth, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (auth.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    auth.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              AppButton(
                label: 'Sign in',
                isLoading: auth.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
