import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/usage_provider.dart';
import '../providers/user_provider.dart';
import 'package:screen_time/theme/app_theme.dart';
import '../api.dart';
import 'Entry.dart';
import 'History.dart';
import 'Usage.dart';
import 'ScreentimeView.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final usageNotifier = ref.read(usageProvider.notifier);
    final isAndroid = usageNotifier.isAndroid;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Sömndagbok',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: AppTheme.primary)),
        centerTitle: true,
        elevation: 0.5,
        shadowColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppTheme.primary),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'logout') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logga ut'),
                    content: const Text(
                        'Är du säker på att du vill logga ut? Detta kommer att rensa all lokal data. Dina anteckningar kommer att sparas.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Avbryt'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logga ut'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await ref.read(userIdProvider.notifier).setUserId(null);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Du har loggats ut')),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logga ut'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroCard(context, textTheme),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.history_rounded,
                      color: AppTheme.primary),
                  label: const Text(
                    'Se tidigare dagboksanteckningar',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cardBorder,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HistoryPage()),
                    );
                  },
                ),
                if (isAndroid) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.phone_android,
                        color: AppTheme.primary),
                    label: const Text(
                      'Se skärmtidsdata',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cardBorder,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      await usageNotifier.checkUsageStatsPermission();
                      final refreshedUsageState = ref.read(usageProvider);
                      if (!refreshedUsageState.hasPermission) {
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const UsagePage()),
                          );
                        }
                        return;
                      }
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ScreentimeViewPage()),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, TextTheme textTheme) {
    return FutureBuilder<List<Questionnaire>>(
      future: fetchQuestionnaires(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final questionnaire = snapshot.data!
            .firstWhere((q) => q.id == 't0f34uiz4jal947', orElse: () {
          return snapshot.data!.first;
        });

        return Consumer(
          builder: (context, ref, child) {
            final userState = ref.watch(userIdProvider);
            final userId = userState.userId;

            if (userId == null || userId.isEmpty) {
              return _buildDefaultHeroCard(context, textTheme, questionnaire);
            }

            return FutureBuilder<bool>(
              future: _checkTodayEntryExists(userId),
              builder: (context, entrySnapshot) {
                if (entrySnapshot.connectionState == ConnectionState.waiting) {
                  return _buildDefaultHeroCard(
                      context, textTheme, questionnaire);
                }

                final hasEntryToday = entrySnapshot.data ?? false;

                if (hasEntryToday) {
                  return _buildCompletedHeroCard(context, textTheme);
                } else {
                  return _buildDefaultHeroCard(
                      context, textTheme, questionnaire);
                }
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _checkTodayEntryExists(String userId) async {
    try {
      final answers = await fetchUserAnswers(userId);
      final today = DateTime.now();
      final todayStr =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      for (final answer in answers) {
        final dateStr = (answer['date'] ?? answer['created'] ?? '').toString();
        if (dateStr.isNotEmpty) {
          final answerDate = DateTime.tryParse(dateStr.replaceFirst(' ', 'T'));
          if (answerDate != null) {
            final answerDateStr =
                "${answerDate.year}-${answerDate.month.toString().padLeft(2, '0')}-${answerDate.day.toString().padLeft(2, '0')}";
            if (answerDateStr == todayStr) {
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Widget _buildCompletedHeroCard(BuildContext context, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 76, 175, 80),
            Color.fromARGB(255, 56, 142, 60)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 224, 227, 231)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.check_circle,
              size: 120,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bra jobbat!',
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Du har redan fyllt i dagens dagbok.',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultHeroCard(
      BuildContext context, TextTheme textTheme, Questionnaire questionnaire) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 91, 192, 190),
            Color.fromARGB(255, 91, 192, 190)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 224, 227, 231)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.nightlight_round,
              size: 120,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'God morgon!',
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dags att logga nattens sömn.',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppTheme.primary.withAlpha((0.9 * 255).round()),
                  ),
                ),
                const SizedBox(height: 24),
                Consumer(
                  builder: (context, ref, child) {
                    return OutlinedButton.icon(
                      icon: const Icon(Icons.add, color: AppTheme.primary),
                      label: const Text('Fyll i dagbok',
                          style: TextStyle(color: AppTheme.primary)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppTheme.primary, width: 1.2),
                        backgroundColor:
                            AppTheme.background.withAlpha((0.7 * 255).round()),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  NewEntryPage(questionnaire: questionnaire)),
                        );

                        if (result == true && context.mounted) {
                          ref.invalidate(userIdProvider);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
