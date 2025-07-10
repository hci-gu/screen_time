import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:screen_time/providers/questionnaire_provider.dart';
import 'package:screen_time/providers/usage_provider.dart';
import 'package:screen_time/providers/user_provider.dart';
import 'package:screen_time/services/foreground_service.dart';
import 'package:screen_time/widgets/date_selector.dart';
import 'package:screen_time/widgets/grant_permission_view.dart';
import 'package:screen_time/widgets/upload_button.dart';
import 'package:screen_time/widgets/usage_graph.dart';
import 'package:screen_time/widgets/usage_list.dart';
import 'package:screen_time/api.dart' as api;

class QuestionnaireList extends ConsumerWidget {
  const QuestionnaireList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(questionnaireProvider).when(
          data: (questionnaires) {
            if (questionnaires.isEmpty) {
              return const Center(child: Text('No questionnaires available'));
            }

            return ListView.builder(
              itemCount: questionnaires.length,
              itemBuilder: (context, index) {
                final questionnaire = questionnaires[index];
                return ListTile(
                  title: Text(questionnaire.id),
                  onTap: () {
                    // Handle questionnaire tap
                    api.answerQuestionnaire(
                        ref.read(userIdProvider) ?? '', questionnaire.id, {
                      "hey": "ho",
                      "let's": "go",
                    });
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final usageNotifier = ref.read(usageProvider.notifier);
    final usageState = ref.watch(usageProvider);
    final userId = ref.watch(userIdProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Screen time tracker"),
      ),
      body: !usageState.hasPermission
          ? const GrantPermissionView()
          : const QuestionnaireList(),
      floatingActionButton:
          !usageState.hasPermission ? null : const UploadButton(),
    );
  }
}
