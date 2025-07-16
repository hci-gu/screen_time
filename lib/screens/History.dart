import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../api.dart';
import '../providers/user_provider.dart';
import 'ViewForm.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

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
            Icon(Icons.history_edu_outlined,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text('Inga anteckningar',
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Du har inte fyllt i några formulär ännu. Dina svar kommer att visas här.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
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
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
            const SizedBox(height: 24),
            Text('Ett fel uppstod',
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Kunde inte ladda dina tidigare anteckningar. Vänligen försök igen senare.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
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
      shadowColor: Colors.black.withOpacity(0.1),
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
              Icon(Icons.description_outlined,
                  color: theme.primaryColor, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle.isNotEmpty ? subtitle : 'Tid okänd',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userIdProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tidigare anteckningar'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
      ),
      body: userId == null || userId.isEmpty
          ? const Center(child: Text('Ingen användare inloggad.'))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchUserAnswers(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _buildErrorState(context, snapshot.error.toString());
                }

                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return _buildEmptyState(context, userId);
                }

                entries.sort((a, b) {
                  final dateA = DateTime.tryParse(
                      (a['date'] ?? a['created'] ?? '').replaceFirst(' ', 'T'));
                  final dateB = DateTime.tryParse(
                      (b['date'] ?? b['created'] ?? '').replaceFirst(' ', 'T'));
                  if (dateA == null || dateB == null) return 0;
                  return dateB.compareTo(dateA);
                });

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _buildEntryCard(context, entry);
                  },
                );
              },
            ),
    );
  }
}
