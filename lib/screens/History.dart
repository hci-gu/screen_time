import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_time/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../api.dart';
import '../providers/user_provider.dart';
import '../utils/network_utils.dart';
import 'ViewForm.dart';
import 'Entry.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  int _refreshKey = 0;

  (String, String) _parseAndFormatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return ('Okänt datum', '');
    }

    final sanitizedString = dateTimeString.replaceFirst(' ', 'T');

    try {
      final dateTime = DateTime.parse(sanitizedString);
      final date = DateFormat('d MMM yyyy').format(dateTime);
      final time = DateFormat('HH:mm').format(dateTime);
      return (date, 'Kl. $time');
    } catch (e) {
      try {
        final dateTime = DateTime.parse(dateTimeString);
        final date = DateFormat('d MMM yyyy').format(dateTime);
        final time = DateFormat('HH:mm').format(dateTime);
        return (date, 'Kl. $time');
      } catch (e2) {
        return (dateTimeString.split(' ').first, '');
      }
    }
  }

  Widget _buildEmptyState(BuildContext context, String userId) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_edu_outlined,
                size: 80, color: AppTheme.cardBorder),
            const SizedBox(height: 24),
            Text('Inga anteckningar',
                style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 8),
            Text(
              'Du har inte fyllt i några formulär ännu. Dina svar kommer att visas här.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: AppTheme.cardBorder),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: AppTheme.error),
            const SizedBox(height: 24),
            Text('Ett fel uppstod',
                style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: AppTheme.error)),
            const SizedBox(height: 8),
            Text(
              'Kunde inte ladda dina tidigare anteckningar. Vänligen försök igen senare.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: AppTheme.cardBorder),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoNetworkState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off,
                size: 80, color: Color.fromARGB(255, 255, 152, 0)),
            const SizedBox(height: 24),
            Text('Ingen internetanslutning',
                style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 255, 152, 0))),
            const SizedBox(height: 8),
            Text(
              'Du behöver internetanslutning för att ladda dina tidigare anteckningar. Kontrollera din anslutning och försök igen.',
              textAlign: TextAlign.center,
              style: AppTheme.body,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: AppTheme.primary),
              label: const Text('Försök igen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.background,
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary, width: 1.2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                setState(() {
                  _refreshKey++;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, Map<String, dynamic> entry) {
    final (date, subtitle) =
        _parseAndFormatDateTime(entry['date'] ?? entry['created']);

    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shadowColor: AppTheme.primary.withAlpha((0.1 * 255).round()),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EntryDetailPage(entry: entry),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.description_outlined,
                  color: AppTheme.primary, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.cardBorder),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userIdProvider);
    final userId = userState.userId;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tidigare anteckningar',
            style: TextStyle(color: AppTheme.primary)),
        backgroundColor: AppTheme.background,
        surfaceTintColor: AppTheme.background,
        elevation: 1,
      ),
      body: userId == null || userId.isEmpty
          ? const Center(child: Text('Ingen användare inloggad.'))
          : FutureBuilder<bool>(
              key: ValueKey(_refreshKey),
              future: NetworkUtils.hasNetworkConnection(),
              builder: (context, networkSnapshot) {
                if (networkSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final hasNetwork = networkSnapshot.data ?? false;
                if (!hasNetwork) {
                  return _buildNoNetworkState(context);
                }

                return FutureBuilder<DateTime?>(
                  future: fetchUserStartDate(userId),
                  builder: (context, startSnapshot) {
                    if (startSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final startDate = startSnapshot.data;
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchUserAnswers(userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          if (NetworkUtils.isNetworkError(snapshot.error)) {
                            return _buildNoNetworkState(context);
                          }
                          return _buildErrorState(
                              context, snapshot.error.toString());
                        }

                        final entries = snapshot.data ?? [];
                        if (entries.isEmpty) {
                          return _buildEmptyState(context, userId);
                        }

                        List<Map<String, dynamic>> afterStart = [];
                        Set<String> filledDays = {};
                        for (final entry in entries) {
                          final dateStr =
                              (entry['date'] ?? entry['created'] ?? '')
                                  .replaceFirst(' ', 'T');
                          final date = DateTime.tryParse(dateStr);
                          if (startDate != null &&
                              date != null &&
                              !date.isBefore(startDate)) {
                            final start = DateTime(
                                startDate.year, startDate.month, startDate.day);
                            final entryDay =
                                DateTime(date.year, date.month, date.day);
                            final dayNumber =
                                entryDay.difference(start).inDays + 1;
                            if (dayNumber <= 10) {
                              afterStart
                                  .add({...entry, 'dayNumber': dayNumber});
                              filledDays.add(
                                  "${entryDay.year}-${entryDay.month.toString().padLeft(2, '0')}-${entryDay.day.toString().padLeft(2, '0')}");
                            }
                          }
                        }

                        List<Widget> allDayWidgets = [];
                        if (startDate != null) {
                          final start = DateTime(
                              startDate.year, startDate.month, startDate.day);
                          const studyDays = 10;

                          Map<int, Map<String, dynamic>> entryByDayNumber = {};
                          for (final entry in afterStart) {
                            final dayNumber = entry['dayNumber'] as int?;
                            if (dayNumber != null && dayNumber <= studyDays) {
                              entryByDayNumber[dayNumber] = entry;
                            }
                          }

                          for (int i = 0; i < studyDays; i++) {
                            final day = start.add(Duration(days: i));
                            final dayNumber = i + 1;

                            if (entryByDayNumber.containsKey(dayNumber)) {
                              final entry = entryByDayNumber[dayNumber]!;
                              allDayWidgets.add(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 4.0),
                                      child: Text('Dag $dayNumber',
                                          style: TextStyle(
                                              color: AppTheme.primary)),
                                    ),
                                    _buildEntryCard(context, entry),
                                  ],
                                ),
                              );
                            } else {
                              allDayWidgets.add(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 4.0),
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.add,
                                        color: AppTheme.primary),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.cardBorder,
                                      foregroundColor: AppTheme.primary,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 16),
                                    ),
                                    label: Text(
                                        'Fyll i dagbok för dag $dayNumber (${DateFormat('d MMM yyyy').format(day)})'),
                                    onPressed: () async {
                                      final hasNetworkForForm =
                                          await NetworkUtils
                                              .hasNetworkConnection();
                                      if (!hasNetworkForForm) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Row(
                                                children: [
                                                  Icon(Icons.wifi_off,
                                                      color: Colors.white),
                                                  SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Ingen internetanslutning. Internetanslutning krävs för att fylla i dagbok.',
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Color.fromARGB(
                                                  255, 255, 152, 0),
                                              duration: Duration(seconds: 4),
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      try {
                                        final questionnaires =
                                            await fetchQuestionnaires();
                                        final questionnaire =
                                            questionnaires.isNotEmpty
                                                ? questionnaires.first
                                                : null;
                                        if (questionnaire != null &&
                                            context.mounted) {
                                          final result =
                                              await Navigator.of(context)
                                                  .push<bool>(
                                            MaterialPageRoute(
                                              builder: (_) => NewEntryPage(
                                                questionnaire: questionnaire,
                                                initialDate: day,
                                              ),
                                            ),
                                          );

                                          if (result == true && mounted) {
                                            setState(() {
                                              _refreshKey++;
                                            });
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          final errorMessage =
                                              NetworkUtils.getErrorMessage(e,
                                                  customNetworkMessage:
                                                      'Internetanslutningen bröts. Kontrollera din anslutning och försök igen.');

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  Icon(
                                                    NetworkUtils.isNetworkError(
                                                            e)
                                                        ? Icons.wifi_off
                                                        : Icons.error_outline,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      errorMessage,
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor:
                                                  NetworkUtils.isNetworkError(e)
                                                      ? const Color.fromARGB(
                                                          255, 255, 152, 0)
                                                      : Colors.red,
                                              duration:
                                                  const Duration(seconds: 4),
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

                        return ListView(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          children: allDayWidgets,
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
