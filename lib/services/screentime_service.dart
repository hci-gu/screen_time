import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:screen_time/providers/usage_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void startScreentimeService() {
  FlutterForegroundTask.setTaskHandler(ScreentimeServiceHandler());
}

class ScreentimeServiceHandler extends TaskHandler {
  // StreamSubscription<StepCount>? _stepCountSubs;
  // StreamSubscription<PedestrianStatus>? _pedestrianStatusSubs;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    DartPluginRegistrant.ensureInitialized();
    // _stepCountSubs = Pedometer.stepCountStream.listen(_onStepCount);
    // _pedestrianStatusSubs =
    //     Pedometer.pedestrianStatusStream.listen(_onPedestrianStatusChanged);
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    final notifier = UsageNotifier();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");

    if (userId == null) {
      return;
    }
    try {
      await notifier.uploadData(userId);
    } catch (_) {}
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // _stepCountSubs?.cancel();
    // _pedestrianStatusSubs?.cancel();
  }

  // void _onStepCount(StepCount event) {
  //   final MyStepCount data =
  //       MyStepCount(steps: event.steps, timestamp: event.timeStamp);
  //   dev.log("PedometerServiceHandler::onStepCount: $event");

  //   FlutterForegroundTask.sendDataToMain(data.toJson());
  // }

  // void _onPedestrianStatusChanged(PedestrianStatus event) {
  //   final MyPedestrianStatus data =
  //       MyPedestrianStatus(status: event.status, timestamp: event.timeStamp);
  //   dev.log("PedometerServiceHandler::onPedestrianStatusChanged: $event");

  //   FlutterForegroundTask.sendDataToMain(data.toJson());
  // }
}
