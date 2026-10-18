import 'package:front_end_flutter/widgets/enad_panel/enad_panel.dart';
import 'package:front_end_flutter/widgets/level_badge/level_badge.dart';
import 'package:front_end_flutter/models/level/level.dart';
import 'package:front_end_flutter/models/student/student.dart';
import 'package:front_end_flutter/widgets/student_card/student_card.dart';
import 'package:front_end_flutter/viewmodels/classification_viewmodel/classification_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/models/group/group.dart';
import 'package:front_end_flutter/viewmodels/grupos_viewmodel/grupos_viewmodel.dart';
import 'package:front_end_flutter/viewmodels/group_detail_viewmodel/group_detail_viewmodel.dart';
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
