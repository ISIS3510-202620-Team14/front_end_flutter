# front_end_flutter

Native prototype of ENAd Móvil (all in a teachers interface), built with Flutter.
Authentication uses Firebase Auth and the register/login HTTP endpoints. Some classroom screens still use prototype data.

## Execution

Requirements:
- Flutter 3.38.4 or later versions
- Dart 3.13.3 or later versions

From the root folder of the project (`front_end_flutter`), run:

    flutter pub get
    flutter run -d chrome

## Implementation

### Samuel Charry: Login and Home

The login is the first screen of the app, so it can be found as soon as the app is opened.
Create an account with your name, email and password, or sign in with an existing Firebase account. New accounts receive the sin_privilegios role; an administrator assigns the docente role and schoolIds. Firebase restores the session when reopening the app. Cambiar usuario signs out.

**Login**
- `lib/views/login_view.dart`
- `lib/viewmodels/login_viewmodel.dart`
- `lib/widgets/login_button.dart`

**Home shell** (top bar, bottom navigation and tab switching)
- `lib/views/home_shell.dart`
- `lib/widgets/home_top_bar.dart`
- `lib/widgets/home_bottom_nav.dart`

**Hoy tab** (subject progress and quick actions)
- `lib/views/hoy_view.dart`
- `lib/viewmodels/home_viewmodel.dart`
- `lib/widgets/subject_progress_card.dart`
- `lib/widgets/quick_action_card.dart`
- `lib/models/subject_progress.dart`
- `lib/models/quick_action.dart`

### Isabela Mantilla: Reading and Math classification

On Home, click on the Lectura or Matemáticas card. A screen opens in which students from different grades appear (they can be filtered by Todos, Grado 3, 4 or 5). You can assess their level, update their sex and age, and mark them as Retirado, which moves them to "Fuera del colegio". The active-student counters and the progress percentages on Home update automatically.

- `lib/views/classification_view.dart`
- `lib/viewmodels/classification_viewmodel.dart`
- `lib/viewmodels/students_viewmodel.dart` (student list shared with Home)
- `lib/widgets/student_card.dart`
- `lib/widgets/course_chips.dart`
- `lib/widgets/level_chip.dart`
- `lib/widgets/section_label.dart`
- `lib/models/student.dart`
- `lib/models/level.dart`

### Juan Triviño: Groups and Hours

The Groups and Hours screens can be found in the navigation bar at the bottom of the Home. In which you can see the courses and the hours dedicated.

**Grupos**
- `lib/views/grupos_view.dart`
- `lib/viewmodels/grupos_viewmodel.dart`
- `lib/widgets/group_card.dart`
- `lib/widgets/create_group_card.dart`
- `lib/widgets/empty_groups_state.dart`
- `lib/widgets/pending_children_notice.dart`
- `lib/widgets/subject_tab_bar.dart`
- `lib/models/group.dart`

**Horas**
- `lib/views/horas_view.dart`
- `lib/viewmodels/horas_viewmodel.dart`
- `lib/widgets/hours_heatmap.dart`
- `lib/widgets/hours_difference_notice.dart`
- `lib/widgets/hours_number_field.dart`
- `lib/widgets/hours_period_selector.dart`
- `lib/widgets/hours_reason_field.dart`

## Firebase authentication

By default the app connects to the configured Firebase project. For local testing:

    flutter run --dart-define=USE_EMULATORS=true

Start Auth (9099), Firestore (8080) and Functions (5001) emulators in the backend first. Android emulators use 10.0.2.2; web and desktop use 127.0.0.1. A physical phone needs a reachable host configuration.

Protected HTTP endpoints must use AuthApi.getIdToken() in Authorization: Bearer <token>. The customToken returned by login is only for opening the Firebase session. Passwords are managed by Firebase Auth.

## Activity usage business question

The Activities screen shows the percentage of the signed-in teacher's planned activities taken from the library versus created by that teacher. See [BQ type 2: activity usage](docs/BQ2-uso-de-actividades.md) for the calculation, data flow, and wiki evidence.
