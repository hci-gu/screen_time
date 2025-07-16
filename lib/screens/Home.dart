import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/usage_provider.dart';
import '../providers/user_provider.dart';
import '../api.dart';
import 'Entry.dart';
import 'History.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final usageNotifier = ref.read(usageProvider.notifier);
    final userId = ref.watch(userIdProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Sömndagbok',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 28, 37, 65))),
        centerTitle: true,
        elevation: 0.5,
        shadowColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 28, 37, 65)),
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
                        'Är du säker på att du vill logga ut? Detta kommer att rensa all lokal data. Dina anteckingar kommer att sparas.'),
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
                      color: Color.fromARGB(255, 28, 37, 65)),
                  label: const Text(
                    'Se tidigare dagboksanteckningar',
                    style: TextStyle(
                      color: Color.fromARGB(255, 28, 37, 65),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 224, 227, 231),
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
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload,
                      color: Color.fromARGB(255, 28, 37, 65)),
                  label: const Text(
                    'Ladda upp skärmtid (7 dagar)',
                    style: TextStyle(
                      color: Color.fromARGB(255, 28, 37, 65),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 224, 227, 231),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (userId != null && userId.isNotEmpty) {
                      final success =
                          await usageNotifier.uploadLast7Days(userId);
                      final snackBar = SnackBar(
                        content: Text(success
                            ? 'Uppladdning lyckades!'
                            : 'Uppladdning misslyckades.'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Ingen användar-ID hittades.')),
                      );
                    }
                  },
                ),
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
                        color: const Color.fromARGB(255, 28, 37, 65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dags att logga nattens sömn.',
                      style: textTheme.titleMedium?.copyWith(
                        color: const Color.fromARGB(255, 28, 37, 65)
                            .withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add,
                          color: Color.fromARGB(255, 28, 37, 65)),
                      label: const Text('Fyll i dagbok',
                          style: TextStyle(
                              color: Color.fromARGB(255, 28, 37, 65))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color.fromARGB(255, 28, 37, 65), width: 1.2),
                        backgroundColor: Colors.white.withValues(alpha: 0.7),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  NewEntryPage(questionnaire: questionnaire)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
