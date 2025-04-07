import 'package:flutter/material.dart';

class DateButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  const DateButton({Key? key, required this.onPressed, required this.icon})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: onPressed, icon: Icon(icon));
  }
}
