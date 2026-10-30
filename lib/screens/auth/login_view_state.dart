// lib/screens/auth/login_view_state.dart
part of 'login_view.dart';

class _LoginViewState extends State<LoginView> {
  final _viewModel = LoginViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return const RegisterView();
        },
      ),
    );
  }

  /** Logs in and, when it worked, lets the phone offer to save the password. */
  Future<void> _submit() async {
    final opened = await _viewModel.login();
    if (opened) {
      TextInput.finishAutofillContext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              final IconData passwordVisibilityIcon;
              final String passwordVisibilityLabel;
              if (_viewModel.obscurePassword) {
                passwordVisibilityIcon = Icons.visibility_outlined;
                passwordVisibilityLabel = 'Mostrar contraseña';
              } else {
                passwordVisibilityIcon = Icons.visibility_off_outlined;
                passwordVisibilityLabel = 'Ocultar contraseña';
              }
              return ListView(
                children: [
                  const SizedBox(height: 60),
                  Image.asset(
                    'assets/branding/enad_logo.png',
                    height: 90,
                    fit: BoxFit.contain,
                    semanticLabel: 'ENAd, Enseñar al nivel adecuado',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa con tu correo y contraseña.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 40),

                  AutofillGroup(
                    child: Column(
                      children: [
                        TextField(
                          controller: _viewModel.emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          autocorrect: false,
                          onChanged: (_) {
                            _viewModel.clearError();
                          },
                          decoration: appInputDecoration(
                            'Usuario (correo)',
                            floatingLabel: false,
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _viewModel.passwordController,
                          obscureText: _viewModel.obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          autocorrect: false,
                          enableSuggestions: false,
                          onChanged: (_) {
                            _viewModel.clearError();
                          },
                          onSubmitted: (_) {
                            _submit();
                          },
                          decoration: appInputDecoration(
                            'Contraseña',
                            floatingLabel: false,
                            suffixIcon: IconButton(
                              tooltip: passwordVisibilityLabel,
                              icon: Icon(
                                passwordVisibilityIcon,
                                color: AppTheme.softInk,
                              ),
                              onPressed: _viewModel.toggleObscurePassword,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_viewModel.error != null) ...[
                    Text(
                      _viewModel.error!,
                      style: const TextStyle(color: AppTheme.red),
                    ),
                    const SizedBox(height: 16),
                  ],

                  LoginButton(
                    onPressed: _submit,
                    isLoading: _viewModel.isLoading,
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: TextButton(
                      onPressed: _goToRegister,
                      child: const Text(
                        '¿No tienes cuenta? Regístrate',
                        style: TextStyle(color: AppTheme.red),
                      ),
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
