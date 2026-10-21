import 'package:front_end_flutter/viewmodels/task_tutorial_controller/task_tutorial_controller.dart';
import 'package:front_end_flutter/widgets/tutorial_overlay/tutorial_frame.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/viewmodels/home_viewmodel/home_viewmodel.dart';
import 'package:front_end_flutter/views/classification_view/classification_view.dart';
import 'package:front_end_flutter/widgets/subject_progress_card/subject_progress_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return TutorialFrame(
      controller: tutorial,
      from: 1,
      to: 1,
      child: Scaffold(
        appBar: AppBar(title: const Text('Evaluación formativa')),
        body: ListenableBuilder(
          listenable: viewModel,
          builder: (BuildContext context, Widget? child) {
            return ListView(
              key: tutorial?.keyFor('evaluation', 1),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
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
