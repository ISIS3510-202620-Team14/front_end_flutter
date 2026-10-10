import 'package:front_end_flutter/models/group/group.dart';
import 'package:front_end_flutter/services/safe_notifier/safe_notifier.dart';
import 'package:front_end_flutter/viewmodels/grupos_viewmodel/grupos_viewmodel.dart';

class GroupDetailViewModel extends SafeNotifier {
  GroupDetailViewModel(this.group, this.groups);
  Group group;
  final GruposViewModel groups;
  bool busy = false;
  String? error;
  Future<void> load() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      group = Group.fromJson(await groups.detail(group.id));
    } catch (failure) {
      error = failure.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> rename(String name) async {
    await _perform(() async {
      await groups.renameGroup(group.id, name);
    });
  }

  Future<void> membership(String studentId, bool selected) async {
    await _perform(() async {
      if (selected) {
        await groups.addStudent(group.id, studentId);
      } else {
        await groups.removeStudent(group.id, studentId);
      }
    });
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (busy) {
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      group = Group.fromJson(await groups.detail(group.id));
    } catch (failure) {
      error = failure.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
