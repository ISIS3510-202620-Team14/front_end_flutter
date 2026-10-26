part of 'profile_view.dart';

class _ProfileViewState extends State<ProfileView> {
  late final TextEditingController _name;
  late final ReportHistoryViewModel _history = ReportHistoryViewModel(
    repository: widget.hoursRepository,
  );
  late final TeacherMetricsViewModel _metrics = TeacherMetricsViewModel(
    students: widget.groups.students,
  );
  bool _saving = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.session.profile!.name);
    _history.load();
  }

  @override
  void dispose() {
    _name.dispose();
    _history.dispose();
    _metrics.dispose();
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
    return ListenableBuilder(
      listenable: Listenable.merge([
        _history,
        widget.groups,
        _metrics,
        widget.groups.students,
      ]),
      builder: (BuildContext context, Widget? child) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            const BrandHeading(title: 'Mis datos'),
            const SizedBox(height: 24),
            EnadPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _name,
                    enabled: !_saving,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Correo',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(profile.email),
                  const SizedBox(height: 16),
                  Text(
                    'Instituciones',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final Map<String, dynamic> school
                      in widget.session.schools)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(school['name'] as String),
                          Text(
                            'Municipio: ${school['municipality'] ?? 'No informado'}',
                          ),
                          for (final dynamic campus
                              in school['campuses'] as List? ?? [])
                            if ((profile.campusIds[school['id']] ?? [])
                                .contains(campus['id']))
                              Text('Sede: ${campus['name']}'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: saveAction,
                      child: const Text('Guardar nombre'),
                    ),
                  ),
                  if (_message != null) Text(_message!),
                ],
              ),
            ),
            const SizedBox(height: 16),
            EnadPanel(
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 12),
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  'Mis grupos (${widget.groups.allGroups.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                children: [
                  if (widget.groups.loading) const LinearProgressIndicator(),
                  if (widget.groups.error != null)
                    EnadPanel(child: Text(widget.groups.error!))
                  else if (widget.groups.allGroups.isEmpty &&
                      !widget.groups.loading)
                    const EnadPanel(
                      child: Text(
                        'Todavía no tienes grupos en la institución seleccionada.',
                      ),
                    ),
                  for (final Group group in widget.groups.allGroups) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(group.name),
                      subtitle: Text(
                        '${group.subject} · ${group.studentIds.length} estudiantes',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) {
                              return GroupDetailView(
                                group: group,
                                groups: widget.groups,
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) {
                      return StudentRosterView(
                        viewModel: widget.groups.students,
                        schools: widget.session.schools,
                      );
                    },
                  ),
                );
              },
              icon: const Icon(Icons.person_add_alt_outlined),
              label: const Text('Gestionar estudiantes'),
            ),
            const SizedBox(height: 16),
            EnadPanel(
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 12),
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  'Reportes de horas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                onExpansionChanged: (bool expanded) {
                  if (expanded && !_history.loading) {
                    _history.load();
                  }
                },
                children: [
                  Text(
                    'Últimos 30 días y reportes pendientes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (_history.notice != null) Text(_history.notice!),
                  if (_history.loading)
                    const LinearProgressIndicator()
                  else if (_history.error != null)
                    Text(_history.error!)
                  else if (_history.receipts.isEmpty)
                    const Text('Sin reportes de horas en este periodo.')
                  else
                    for (final Map<String, dynamic> receipt
                        in _history.receipts) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              receipt['date'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          RecordStatus(
                            label: HoursRepository.statusLabel(receipt),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${receipt['workedHours']} h realizadas de ${receipt['plannedHours']} h programadas',
                      ),
                      Text(
                        widget.session.schools.where((school) {
                                  return school['id'] == receipt['schoolId'];
                                }).firstOrNull?['name']
                                as String? ??
                            receipt['schoolId'] as String? ??
                            'Institución sin registrar',
                      ),
                      if (receipt['syncError'] != null)
                        Text(receipt['syncError'] as String),
                      const Divider(height: 24),
                    ],
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _history.loading ? null : _history.load,
                    child: const Text('Actualizar y enviar pendientes'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TeacherMetricsPanel(
              model: _metrics,
              receipts: _history.receipts,
              hoursError: _history.error,
              hoursLoading: _history.loading,
            ),
            const SizedBox(height: 16),
            AttendancePendingPanel(
              userId: profile.uid,
              onOpen: widget.onAttendance,
            ),
            const SizedBox(height: 16),
            EnadPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton.icon(
                    onPressed: widget.session.logout,
                    icon: const Icon(Icons.switch_account_outlined),
                    label: const Text('Cambiar usuario'),
                  ),
                  TextButton.icon(
                    onPressed: widget.session.logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
