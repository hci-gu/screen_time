import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/usage_provider.dart';

class UploadButton extends ConsumerWidget {
  const UploadButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageNotifier = ref.read(usageProvider.notifier);
    return FloatingActionButton(
      onPressed: () => usageNotifier.uploadData(),
      tooltip: 'Upload Data',
      child: const Icon(Icons.cloud_upload),
    );
  }
}
