import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/input_styles.dart';
import '../viewmodels/register_viewmodel.dart';
import '../widgets/login_button.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _viewModel = RegisterViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final creada = await _viewModel.register();
    // Esta pantalla está encima del AuthGate: hay que cerrarla para
    // que se vea la app con la sesión ya abierta.
    if (creada && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        foregroundColor: AppTheme.ink,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Crear cuenta',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 32),

                  TextField(
                    controller: _viewModel.nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: appInputDecoration('Nombre completo'),
                  ),
                  const SizedBox(height: 16),

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
                    onPressed: _submit,
                    label: 'Crear cuenta',
                    isLoading: _viewModel.isLoading,
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
