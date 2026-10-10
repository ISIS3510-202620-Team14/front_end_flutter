part of 'hours_reason_field.dart';

class _HoursReasonFieldState extends State<HoursReasonField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      minLines: 3,
      maxLines: 5,
      style: const TextStyle(color: AppTheme.ink),
      decoration: InputDecoration(
        hintText: 'Motivo de horas no realiza...',
        hintStyle: const TextStyle(color: AppTheme.softInk),
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppTheme.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppTheme.red, width: 1.5),
        ),
      ),
    );
  }
}
