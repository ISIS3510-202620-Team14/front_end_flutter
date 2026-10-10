part of 'profile_view.dart';

class _ProfileViewState extends State<ProfileView> {
  late final TextEditingController _name;
  bool _saving = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.session.profile!.name);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await widget.session.saveName(_name.text);
      _message = 'Nombre guardado.';
    } catch (_) {
      _message = 'No pudimos guardar el nombre.';
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.session.profile!;
    final Future<void> Function()? saveAction;
    if (_saving) {
      saveAction = null;
    } else {
      saveAction = _save;
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Mis datos', style: Theme.of(context).textTheme.headlineLarge),
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        ListTile(title: const Text('Correo'), subtitle: Text(profile.email)),
        ListTile(title: const Text('Rol'), subtitle: Text(profile.role)),
        for (final school in widget.session.schools)
          ListTile(title: Text(school['name'] as String)),
        FilledButton(
          onPressed: saveAction,
          child: const Text('Guardar nombre'),
        ),
        if (_message != null) Text(_message!),
        TextButton(
          onPressed: AuthApi.logout,
          child: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
