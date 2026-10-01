import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/input_styles.dart';
import '../viewmodels/login_viewmodel.dart';
import '../widgets/login_button.dart';
import 'register_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _viewModel = LoginViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return ListView(
                children: [
                  const SizedBox(height: 60),
                  Text('ENAd Móvil',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('Ingresa con tu correo y contraseña.',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 40),

                  TextField(
                    controller: _viewModel.emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: appInputDecoration('Correo'),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _viewModel.passwordController,
                    obscureText: _viewModel.obscurePassword,
                    decoration: appInputDecoration('Contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _viewModel.obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.softInk,
                          ),
                          onPressed: _viewModel.toggleObscurePassword,
                        )),
                  ),
                  const SizedBox(height: 32),

                  if (_viewModel.error != null) ...[
                    Text(_viewModel.error!,
                        style: const TextStyle(color: AppTheme.red)),
                    const SizedBox(height: 16),
                  ],

                  LoginButton(
                    onPressed: _viewModel.login,
                    isLoading: _viewModel.isLoading,
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: TextButton(
                      onPressed: _goToRegister,
                      child: const Text('¿No tienes cuenta? Regístrate',
                          style: TextStyle(color: AppTheme.red)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
