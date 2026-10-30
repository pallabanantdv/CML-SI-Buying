import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_svg_icon.dart';
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
    await context.read<AuthViewModel>().login(
      _username.text.trim(),
      _password.text,
    );
  }

  @override
  Widget build(BuildContext context) => AutofillGroup(
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _username,
            label: 'Email or username',
            required: true,
            autofillHints: const [AutofillHints.username],
            prefixIcon: const AppSvgIcon(icon: AppIconName.person, size: 20),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => Validators.required(value, 'Username'),
          ),
          const SizedBox(height: AppSpacing.standard),
          AppTextField(
            controller: _password,
            label: 'Password',
            required: true,
            isPassword: true,
            autofillHints: const [AutofillHints.password],
            prefixIcon: const AppSvgIcon(icon: AppIconName.lock, size: 20),
            validator: (value) => Validators.required(value, 'Password'),
          ),
          const SizedBox(height: AppSpacing.large),
          Consumer<AuthViewModel>(
            builder: (context, auth, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (auth.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: Semantics(
                      liveRegion: true,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSvgIcon(
                            icon: AppIconName.error,
                            size: 18,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: AppSpacing.small),
                          Expanded(
                            child: Text(
                              auth.errorMessage!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                AppButton(
                  label: 'Sign in',
                  isLoading: auth.isLoading,
                  onPressed: () => unawaited(_submit()),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
