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
