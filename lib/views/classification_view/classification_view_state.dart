part of 'classification_view.dart';

class _ClassificationViewState extends State<ClassificationView> {
  late final ClassificationViewModel _viewModel = ClassificationViewModel(
    title: widget.title,
    studentsViewModel: widget.studentsViewModel,
  );

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Widget _buildStudentCard(Student student) {
    return StudentCard(
      key: ValueKey(student.number),
      student: student,
      level: _viewModel.levelOf(student),
      expanded: _viewModel.isExpanded(student.number),
      onToggle: () {
        return _viewModel.toggleExpanded(student.number);
      },
      onSexChanged: (sex) {
        return _viewModel.updateSex(student.number, sex);
      },
      onAgeChanged: (age) {
        return _viewModel.updateAge(student.number, age);
      },
      levels: _viewModel.subjectLevels,
      withdrawnLevel: ClassificationViewModel.withdrawnLevel,
      onLevelSelected: (level) {
        return _viewModel.setLevel(student.number, level);
      },
    );
  }

  Widget _buildGroup(String title, List<Student> students) {
    if (students.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        SectionLabel('${title.toUpperCase()} · ${students.length}'),
        const SizedBox(height: 10),
        for (final student in students) ...[
          _buildStudentCard(student),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildOutOfSchoolGroup() {
    final students = _viewModel.studentsIn(ClassificationViewModel.withdrawn);
    if (students.isEmpty) {
      return const SizedBox.shrink();
    }

    final IconData expansionIcon;
    if (_viewModel.outOfSchoolExpanded) {
      expansionIcon = Icons.keyboard_arrow_up;
    } else {
      expansionIcon = Icons.keyboard_arrow_down;
    }
    final Color expansionColor;
    if (_viewModel.outOfSchoolExpanded) {
      expansionColor = AppTheme.red;
    } else {
      expansionColor = AppTheme.ink;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _viewModel.toggleOutOfSchool,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Fuera del colegio · ${students.length}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  Icon(expansionIcon, color: expansionColor),
                ],
              ),
            ),
            if (_viewModel.outOfSchoolExpanded) ...[
              const SizedBox(height: 12),
              for (final student in students) ...[
                _buildStudentCard(student),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            if (_viewModel.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.red),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                if (_viewModel.error != null)
                  Text(
                    _viewModel.error!,
                    style: const TextStyle(color: AppTheme.red),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 28),
                      color: AppTheme.ink,
                      onPressed: () {
                        return Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: textTheme.headlineLarge?.copyWith(
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              '${_viewModel.activeCount} de '
                              '${_viewModel.totalCount} estudiantes activos',
                              style: textTheme.bodyLarge?.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const SectionLabel('CURSO DE ORIGEN'),
                const SizedBox(height: 10),
                CourseChips(
                  courses: _viewModel.courses,
                  selected: _viewModel.selectedCourse,
                  onChanged: _viewModel.selectCourse,
                ),
                _buildGroup('Sin evaluar', _viewModel.pendingStudents),
                for (final level in _viewModel.subjectLevels)
                  _buildGroup(level.name, _viewModel.studentsIn(level.name)),
                _buildOutOfSchoolGroup(),
              ],
            );
          },
        ),
      ),
    );
  }
}
