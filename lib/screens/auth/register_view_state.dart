// lib/screens/auth/register_view_state.dart
part of 'register_view.dart';

class _RegisterViewState extends State<RegisterView> {
  late final RegisterViewModel _viewModel = RegisterViewModel(
    schools: widget.schoolsRepository,
  );

  @override
  void initState() {
    super.initState();
    _viewModel.loadSchools();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final creada = await _viewModel.register();

    if (creada && mounted) {
      // Snackbar to inform the user that a welcome email was sent, if applicable.
      if (_viewModel.welcomeEmailSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Te enviamos un correo de bienvenida a ${_viewModel.emailController.text.trim()}.',
            ),
          ),
        );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        foregroundColor: AppTheme.ink,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              final IconData passwordVisibilityIcon;
              if (_viewModel.obscurePassword) {
                passwordVisibilityIcon = Icons.visibility_outlined;
              } else {
                passwordVisibilityIcon = Icons.visibility_off_outlined;
              }
              return ListView(
                children: [
                  Text(
                    'Crear cuenta',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
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
                    decoration: appInputDecoration(
                      'Contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(
                          passwordVisibilityIcon,
                          color: AppTheme.softInk,
                        ),
                        onPressed: _viewModel.toggleObscurePassword,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text('Instituciones y sedes'),
                  if (_viewModel.loadingSchools)
                    const LinearProgressIndicator(),
                  if (_viewModel.schoolsError != null) ...[
                    Text(_viewModel.schoolsError!),
                    TextButton(
                      onPressed: _viewModel.loadSchools,
                      child: const Text('Reintentar'),
                    ),
                  ],
                  for (final school in _viewModel.schools) ...[
                    CheckboxListTile(
                      title: Text(school['name'] as String),
                      value: _viewModel.selectedSchools.containsKey(
                        school['id'],
                      ),
                      onChanged: (value) {
                        _viewModel.selectSchool(
                          school['id'] as String,
                          value == true,
                        );
                      },
                    ),
                    if (_viewModel.selectedSchools.containsKey(school['id']))
                      for (final campus in school['campuses'] as List? ?? [])
                        CheckboxListTile(
                          title: Text(campus['name'] as String),
                          value: _viewModel.selectedSchools[school['id']]!
                              .contains(campus['id']),
                          onChanged: (value) {
                            _viewModel.selectCampus(
                              school['id'] as String,
                              campus['id'] as String,
                              value == true,
                            );
                          },
                        ),
                  ],
                  const SizedBox(height: 16),
                  if (_viewModel.error != null) ...[
                    Text(
                      _viewModel.error!,
                      style: const TextStyle(color: AppTheme.red),
                    ),
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
