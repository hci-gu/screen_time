import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:screen_time/api.dart' as api;
import 'package:screen_time/providers/user_provider.dart';
import 'package:screen_time/providers/usage_provider.dart';
import 'package:screen_time/screens/Usage.dart';
import 'package:screen_time/theme/app_theme.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ValueNotifier<String> userId = useState('');
    ValueNotifier<bool> loading = useState(false);
    final usageState = ref.watch(usageProvider);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    // Use AppTheme for colors

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Skärmtidstracker',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: AppTheme.primary)),
        centerTitle: true,
        elevation: 0.5,
        shadowColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppTheme.primary),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(context, textTheme),
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 400,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.07),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text("Logga in med ditt Användar-ID",
                          style: textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20.0),
                      TextField(
                        onChanged: (value) {
                          userId.value = value;
                        },
                        decoration: InputDecoration(
                          labelText: "Användar-ID",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppTheme.inputFill,
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      OutlinedButton.icon(
                        icon: loading.value
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primary),
                                ),
                              )
                            : const Icon(Icons.login, color: AppTheme.primary),
                        label: loading.value
                            ? Text("Loggar in...",
                                style: TextStyle(color: AppTheme.primary))
                            : Text("Logga in",
                                style: TextStyle(color: AppTheme.primary)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.primary, width: 1.2),
                          backgroundColor: AppTheme.background.withOpacity(0.7),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        onPressed: loading.value
                            ? null
                            : () async {
                                loading.value = true;
                                if (userId.value.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Användar-ID får inte vara tomt"),
                                    ),
                                  );
                                  loading.value = false;
                                  return;
                                }
                                bool exists =
                                    await api.checkUserId(userId.value);
                                await Future.delayed(
                                    const Duration(seconds: 1));
                                if (exists) {
                                  ref
                                      .read(userIdProvider.notifier)
                                      .setUserId(userId.value);
                                  if (!usageState.hasPermission &&
                                      context.mounted) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                          builder: (_) => const UsagePage()),
                                    );
                                    loading.value = false;
                                    return;
                                  }
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Användar-ID finns inte"),
                                    ),
                                  );
                                }
                                loading.value = false;
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, TextTheme textTheme) {
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
        border: Border.all(color: AppTheme.cardBorder),
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
                  'Välkommen!',
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Logga in för att börja spåra din skärmtid och sömn.',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppTheme.primary.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
