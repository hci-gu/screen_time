import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/usage_provider.dart';
import '../providers/user_provider.dart';
import 'package:screen_time/theme/app_theme.dart';
import '../api.dart';
import '../utils/network_utils.dart';
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
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Synkar data innan utloggning...'),
                        ],
                      ),
                    ),
                  );

                  bool syncSuccessful = false;
                  try {
                    final userState = ref.read(userIdProvider);
                    if (userState.userId != null) {
                      syncSuccessful = await ref
                          .read(userIdProvider.notifier)
                          .uploadUserData();
                    }
                  } catch (e) {
                    syncSuccessful = false;
                  }

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }

                  await ref.read(userIdProvider.notifier).logout();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(syncSuccessful ? Icons.check : Icons.warning,
                                color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                syncSuccessful
                                    ? 'Du har loggats ut och all data har synkats'
                                    : 'Du har loggats ut. Viss data kunde inte synkas på grund av nätverksproblem.',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: syncSuccessful
                            ? Colors.green
                            : const Color.fromARGB(255, 255, 152, 0),
                        duration: Duration(seconds: syncSuccessful ? 2 : 4),
                      ),
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
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HistoryPage()),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Kunde inte öppna historik. Försök igen.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
                      try {
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

                        final userState = ref.read(userIdProvider);
                        if (userState.userId != null) {
                          try {
                            await usageNotifier.uploadData(userState.userId!);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.wifi_off,
                                          color: Colors.white),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Kunde inte synka skärmtidsdata. Kontrollera din internetanslutning.',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 255, 152, 0),
                                  duration: const Duration(seconds: 4),
                                  action: SnackBarAction(
                                    label: 'Försök igen',
                                    textColor: Colors.white,
                                    onPressed: () async {
                                      try {
                                        await usageNotifier
                                            .uploadData(userState.userId!);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Skärmtidsdata synkad!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Synkning misslyckades igen'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              );
                            }
                          }
                        }

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ScreentimeViewPage()),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ett fel uppstod. Försök igen.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
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
        if (snapshot.hasError) {
          return _buildErrorHeroCard(context, textTheme, snapshot.error);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildNoDataHeroCard(context, textTheme);
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

            return FutureBuilder<String>(
              future: _getEntryFormState(userId),
              builder: (context, entrySnapshot) {
                if (entrySnapshot.connectionState == ConnectionState.waiting) {
                  return _buildDefaultHeroCard(
                      context, textTheme, questionnaire);
                }

                final state = entrySnapshot.data ?? 'show_form';

                switch (state) {
                  case 'completed_today':
                    return _buildCompletedTodayHeroCard(context, textTheme);
                  case 'study_completed':
                    return _buildStudyCompletedHeroCard(context, textTheme);
                  case 'show_form':
                  default:
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

  Future<String> _getEntryFormState(String userId) async {
    try {
      final startDate = await fetchUserStartDate(userId);
      if (startDate == null) {
        return 'show_form';
      }

      final today = DateTime.now();
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final currentDay = DateTime(today.year, today.month, today.day);
      final dayNumber = currentDay.difference(start).inDays + 1;

      if (dayNumber > 10 || dayNumber < 1) {
        return 'study_completed';
      }

      final hasEntryToday = await _checkTodayEntryExists(userId);

      if (hasEntryToday) {
        return 'completed_today';
      }

      return 'show_form';
    } catch (e) {
      return 'show_form';
    }
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
          final answerDate = DateTime.tryParse(dateStr);
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

  Widget _buildCompletedTodayHeroCard(
      BuildContext context, TextTheme textTheme) {
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

  Widget _buildStudyCompletedHeroCard(
      BuildContext context, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 156, 39, 176),
            Color.fromARGB(255, 103, 58, 183)
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
              Icons.celebration,
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
                  'Studien är klar!',
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tack för ditt deltagande! Du har fyllt i dagboken för alla 10 dagar i studien.',
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
                        final hasNetwork =
                            await NetworkUtils.hasNetworkConnection();

                        if (!hasNetwork) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.wifi_off, color: Colors.white),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Ingen internetanslutning. Internetanslutning krävs för att fylla i dagboken.',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor:
                                    Color.fromARGB(255, 255, 152, 0),
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                          return;
                        }

                        try {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    NewEntryPage(questionnaire: questionnaire)),
                          );

                          if (result == true && context.mounted) {
                            ref.invalidate(userIdProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Dagbok sparad!'),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            final isNetworkError =
                                NetworkUtils.isNetworkError(e);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                        isNetworkError
                                            ? Icons.wifi_off
                                            : Icons.error_outline,
                                        color: Colors.white),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isNetworkError
                                            ? 'Internetanslutningen bröts. Dagboken kunde inte sparas.'
                                            : 'Ett fel uppstod när dagboken skulle sparas.',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
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

  Widget _buildErrorHeroCard(
      BuildContext context, TextTheme textTheme, Object? error) {
    final bool isNetworkError = NetworkUtils.isNetworkError(error);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 255, 152, 0),
            Color.fromARGB(255, 255, 193, 7)
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
              isNetworkError ? Icons.wifi_off : Icons.error_outline,
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
                  isNetworkError
                      ? 'Ingen internetanslutning'
                      : 'Något gick fel',
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isNetworkError
                      ? 'Kontrollera din internetanslutning och försök igen. Internetanslutning krävs för att fylla i dagboken.'
                      : 'Ett oväntat fel inträffade. Försök igen senare.',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Försök igen',
                      style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 1.2),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    final container = ProviderScope.containerOf(context);
                    container.invalidate(userIdProvider);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataHeroCard(BuildContext context, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 158, 158, 158),
            Color.fromARGB(255, 117, 117, 117)
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
              Icons.inbox,
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
                  'Inga formulär tillgängliga',
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Det finns inga formulär att fylla i just nu. Kontrollera din internetanslutning eller försök igen senare.',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Försök igen',
                      style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 1.2),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    final container = ProviderScope.containerOf(context);
                    container.invalidate(userIdProvider);
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
