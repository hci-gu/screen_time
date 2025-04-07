import 'package:flutter/material.dart';

class DateText extends StatelessWidget {
  final String date;
  const DateText({Key? key, required this.date}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Text(date, style: Theme.of(context).textTheme.titleMedium);
  }
}
