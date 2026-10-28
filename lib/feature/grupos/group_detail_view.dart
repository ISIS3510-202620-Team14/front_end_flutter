import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/components/level_badge.dart';
import 'package:front_end_flutter/domain/model/level.dart';
import 'package:front_end_flutter/domain/model/student.dart';
import 'package:front_end_flutter/ui/components/student_card.dart';
import 'package:front_end_flutter/screens/teacher/evaluation/classification_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/domain/model/group.dart';
import 'package:front_end_flutter/feature/grupos/grupos_viewmodel.dart';
import 'package:front_end_flutter/feature/grupos/group_detail_viewmodel.dart';
part 'group_detail_view_state.dart';

class GroupDetailView extends StatefulWidget {
  const GroupDetailView({super.key, required this.group, required this.groups});
  final Group group;
  final GruposViewModel groups;
  @override
  State<GroupDetailView> createState() {
    return _GroupDetailViewState();
  }
}
