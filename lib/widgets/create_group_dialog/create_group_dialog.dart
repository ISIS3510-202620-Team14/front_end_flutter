import 'package:flutter/material.dart';
import 'package:front_end_flutter/services/grouping_analytics_service/grouping_analytics_service.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
import 'package:front_end_flutter/widgets/grouping_method_selector/grouping_method_selector.dart';
part 'create_group_dialog_state.dart';

class CreateGroupDialog extends StatefulWidget {
  final String initialSubject;
  final int estimatedClassSize;
  final Future<GroupingRecommendation> Function({
    required String subject,
    required int classSize,
  })
  recommendationLoader;
  final Future<bool> Function({
    required String name,
    required String subject,
    required GroupingMethod method,
  })
  onConfirm;

  const CreateGroupDialog({
    super.key,
    required this.initialSubject,
    required this.estimatedClassSize,
    required this.recommendationLoader,
    required this.onConfirm,
  });

  @override
  State<CreateGroupDialog> createState() {
    return _CreateGroupDialogState();
  }
}
