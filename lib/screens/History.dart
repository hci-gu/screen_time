import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_time/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../api.dart';
import '../providers/user_provider.dart';
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
          : FutureBuilder<DateTime?>(
              key: ValueKey(_refreshKey),
              future: fetchUserStartDate(userId),
              builder: (context, startSnapshot) {
                if (startSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final startDate = startSnapshot.data;
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchUserAnswers(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
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
                      final dateStr = (entry['date'] ?? entry['created'] ?? '')
                          .replaceFirst(' ', 'T');
                      final date = DateTime.tryParse(dateStr);
                      if (startDate != null &&
                          date != null &&
                          !date.isBefore(startDate)) {
                        final start = DateTime(
                            startDate.year, startDate.month, startDate.day);
                        final entryDay =
                            DateTime(date.year, date.month, date.day);
                        final dayNumber = entryDay.difference(start).inDays + 1;
                        afterStart.add({...entry, 'dayNumber': dayNumber});
                        filledDays.add(
                            "${entryDay.year}-${entryDay.month.toString().padLeft(2, '0')}-${entryDay.day.toString().padLeft(2, '0')}");
                      }
                    }

                    List<Widget> allDayWidgets = [];
                    if (startDate != null) {
                      final today = DateTime.now();
                      final start = DateTime(
                          startDate.year, startDate.month, startDate.day);
                      final totalDays = today.difference(start).inDays + 1;

                      Map<int, Map<String, dynamic>> entryByDayNumber = {};
                      for (final entry in afterStart) {
                        final dayNumber = entry['dayNumber'] as int?;
                        if (dayNumber != null) {
                          entryByDayNumber[dayNumber] = entry;
                        }
                      }

                      for (int i = 0; i < totalDays; i++) {
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
                                      style:
                                          TextStyle(color: AppTheme.primary)),
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
                                  final questionnaires =
                                      await fetchQuestionnaires();
                                  final questionnaire =
                                      questionnaires.isNotEmpty
                                          ? questionnaires.first
                                          : null;
                                  if (questionnaire != null &&
                                      context.mounted) {
                                    final result =
                                        await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => NewEntryPage(
                                          questionnaire: questionnaire,
                                          initialDate: day,
                                          dayNumber: dayNumber,
                                        ),
                                      ),
                                    );

                                    if (result == true && mounted) {
                                      setState(() {
                                        _refreshKey++;
                                      });
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
            ),
    );
  }
}
