// lib/screens/teacher/evaluation/evaluation_menu_view.dart
import 'package:front_end_flutter/feature/tutorials/task_tutorial_controller.dart';
import 'package:front_end_flutter/feature/tutorials/tutorial_frame.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/sync/offline_runtime.dart';
import 'package:front_end_flutter/domain/model/saved_data.dart';
import 'package:front_end_flutter/screens/teacher/home/home_viewmodel.dart';
import 'package:front_end_flutter/screens/teacher/evaluation/classification_view.dart';
import 'package:front_end_flutter/ui/components/offline_notice.dart';
import 'package:front_end_flutter/ui/components/subject_progress_card.dart';

class EvaluationMenuView extends StatelessWidget {
  const EvaluationMenuView({
    super.key,
    required this.viewModel,
    this.schools = const [],
    this.tutorial,
  });
  final TaskTutorialController? tutorial;
  final HomeViewModel viewModel;
  final List<Map<String, dynamic>> schools;

  /** When the saved list was downloaded, only if the last update failed and the saved data is what is shown. */
  static String? _savedAt(OfflineRuntime? runtime) {
    if (runtime == null ||
        !runtime.ready ||
        runtime.downloading ||
        runtime.message == null) {
      return null;
    }
    final DateTime? at = DateTime.tryParse(runtime.downloadedAt ?? '');
    if (at == null) {
      return null;
    }
    return SavedData.when(at);
  }

  @override
  Widget build(BuildContext context) {
    final OfflineRuntime? runtime = OfflineRuntime.current;
    return TutorialFrame(
      controller: tutorial,
      from: 1,
      to: 1,
      child: Scaffold(
        appBar: AppBar(title: const Text('Evaluación formativa')),
        body: ListenableBuilder(
          listenable: Listenable.merge([viewModel, ?runtime]),
          builder: (BuildContext context, Widget? child) {
            final String? savedAt = _savedAt(runtime);
            final List<String> notices = OfflineNotice.messagesFor(
              pending: runtime?.pending ?? 0,
              savedAt: savedAt,
            );
            return ListView(
              key: tutorial?.keyFor('evaluation', 1),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                if (notices.isNotEmpty) ...[
                  OfflineNotice(
                    messages: notices,
                    onRefresh: savedAt == null ? null : runtime!.download,
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Selecciona Lectura o Matemáticas. Después elige el momento de evaluación.',
                ),
                const SizedBox(height: 20),
                for (final subject in viewModel.subjects) ...[
                  InkWell(
                    onTap: () async {
                      tutorial?.advance('evaluation', 1);
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) {
                            return ClassificationView(
                              tutorial: tutorial,
                              title: subject.title,
                              schools: schools,
                              studentsViewModel: viewModel.studentsViewModel,
                            );
                          },
                        ),
                      );
                      if (tutorial?.flow == 'evaluation') {
                        tutorial?.stop();
                      }
                    },
                    child: SubjectProgressCard(data: subject),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
