import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_time/providers/user_provider.dart';
import '../providers/usage_provider.dart';
import 'dart:io';

class UploadButton extends ConsumerWidget {
  const UploadButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    final usageNotifier = ref.read(usageProvider.notifier);
    final userState = ref.watch(userIdProvider);
    return FloatingActionButton(
      onPressed: () => usageNotifier.uploadData(userState.userId ?? ''),
      tooltip: 'Upload Data',
      child: const Icon(Icons.cloud_upload),
    );
  }
}
