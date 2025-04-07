import 'package:flutter/material.dart';

class TimeIcon extends StatelessWidget {
  const TimeIcon({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.access_time,
        color: Theme.of(context).colorScheme.primary);
  }
}
