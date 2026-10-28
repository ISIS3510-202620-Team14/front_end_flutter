part of 'tutorial_overlay.dart';

class _TutorialOverlayState extends State<TutorialOverlay> {
  Timer? _timer;
  Rect? _target;
  int _lastStep = -2;
  String? _lastStudent;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _measure();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _changed();
    });
  }

  void _changed() {
    if (!mounted) return;
    final step = widget.controller.step;
    final student = widget.controller.attendanceStudentId;
    if (step != _lastStep ||
        (widget.controller.flow == 'attendance' &&
            step == 3 &&
            student != _lastStudent)) {
      _lastStudent = student;
      _lastStep = step;
      _target = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || step < 0 || step >= widget.controller.lastStep) return;
        final targetContext = widget.controller.targets[step].currentContext;
        if (targetContext != null) {
          Scrollable.ensureVisible(
            targetContext,
            alignment: widget.controller.flow == 'attendance' && step == 3
                ? 0.65
                : 0.12,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 240),
          );
        }
      });
    }
    setState(() {});
  }

  void _measure() {
    if (!mounted || !widget.controller.active) return;
    final step = widget.controller.step;
    if (step >= widget.controller.lastStep) return;
    final object = widget.controller.targets[step].currentContext
        ?.findRenderObject();
    final root = context.findRenderObject();
    if (object is RenderBox &&
        object.hasSize &&
        root is RenderBox &&
        root.hasSize) {
      final point =
          object.localToGlobal(Offset.zero) - root.localToGlobal(Offset.zero);
      final rect = (point & object.size)
          .inflate(6)
          .intersect(Offset.zero & root.size);
      if (rect != _target) {
        setState(() {
          _target = rect;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (!controller.active) return const SizedBox.shrink();
    final target = controller.complete ? null : _target;
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = Offset.zero & constraints.biggest;
        final blockers = target == null
            ? [screen]
            : [
                Rect.fromLTRB(0, 0, screen.right, target.top),
                Rect.fromLTRB(0, target.bottom, screen.right, screen.bottom),
                Rect.fromLTRB(0, target.top, target.left, target.bottom),
                Rect.fromLTRB(
                  target.right,
                  target.top,
                  screen.right,
                  target.bottom,
                ),
              ];
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ClipPath(
                  clipper: TutorialCutout(target),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: ColoredBox(
                      color: const Color(0xFFFAF6F0).withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ),
            ),
            for (final area in blockers)
              Positioned.fromRect(
                rect: area,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                ),
              ),
            if (target != null)
              Positioned.fromRect(
                rect: target,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE52228).withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 18,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Material(
                    color: Colors.white,
                    elevation: 3,
                    shadowColor: Colors.black12,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!widget.compact)
                            Text(
                              'GUÍA · ${controller.label.toUpperCase()}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          const SizedBox(height: 8),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              controller.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (!widget.compact) Text(controller.instruction),
                          if (controller.feedback != null ||
                              (controller.showsNext &&
                                  controller.requirement != null)) ...[
                            const SizedBox(height: 8),
                            Text(
                              controller.feedback ?? controller.requirement!,
                              style: const TextStyle(color: Color(0xFFB71C1C)),
                            ),
                          ],
                          const SizedBox(height: 12),
                          OverflowBar(
                            alignment: MainAxisAlignment.spaceBetween,
                            overflowAlignment: OverflowBarAlignment.end,
                            children: [
                              TextButton(
                                onPressed: controller.stop,
                                child: Text(
                                  controller.complete ? 'Cerrar' : 'Salir',
                                ),
                              ),
                              if (controller.flow == 'attendance' &&
                                  controller.step > 1 &&
                                  !controller.complete)
                                TextButton(
                                  onPressed: controller.previous,
                                  child: const Text('Atrás'),
                                ),
                              if (controller.showsNext)
                                FilledButton(
                                  onPressed: !controller.canContinue
                                      ? null
                                      : () {
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                          controller.next();
                                        },
                                  child: Text(controller.nextLabel),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
