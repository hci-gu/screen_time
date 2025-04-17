import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_time/providers/user_provider.dart';
import '../providers/usage_provider.dart';

class UploadButton extends ConsumerWidget {
  const UploadButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageNotifier = ref.read(usageProvider.notifier);
    final userId = ref.watch(userIdProvider);
    return FloatingActionButton(
      onPressed: () => usageNotifier.uploadData(userId ?? ''),
      tooltip: 'Upload Data',
      child: const Icon(Icons.cloud_upload),
    );
  }
}
