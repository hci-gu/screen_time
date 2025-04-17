import 'package:flutter/material.dart';

class DateButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  const DateButton({super.key, required this.onPressed, required this.icon});
  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: onPressed, icon: Icon(icon));
  }
}
