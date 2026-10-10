import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final bool isLoading;

  const LoginButton({
    super.key,
    required this.onPressed,
    this.label = 'Entrar',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final void Function()? submitAction;
    if (isLoading) {
      submitAction = null;
    } else {
      submitAction = onPressed;
    }
    final Widget buttonContent;
    if (isLoading) {
      buttonContent = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    } else {
      buttonContent = Text(
        label,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: Colors.white),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(onPressed: submitAction, child: buttonContent),
    );
  }
}
