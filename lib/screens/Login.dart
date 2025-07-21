import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:screen_time/api.dart' as api;
import 'package:screen_time/providers/user_provider.dart';
import 'package:screen_time/providers/usage_provider.dart';
import 'package:screen_time/screens/Usage.dart';
import 'package:screen_time/theme/app_theme.dart';

/// En formatter som hanterar användarid
/// om man skriver "099" -> blir "099-"
/// om man trycker backsteg på "099-" -> blir "09"
class UserIdFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length < oldValue.text.length) {
      if (oldValue.text.endsWith('-') &&
          (oldValue.text.length == 4 || oldValue.text.length == 8)) {
        final newText = oldValue.text.substring(0, oldValue.text.length - 2);

        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
      return newValue;
    }

    final String rawText =
        newValue.text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (rawText.length > 9) {
      return oldValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < rawText.length; i++) {
      buffer.write(rawText[i]);
      if ((i == 2 || i == 5) && i < rawText.length - 1) {
        buffer.write('-');
      }
    }

    String formattedText = buffer.toString();

    if ((rawText.length == 3 || rawText.length == 6) &&
        newValue.text.length > oldValue.text.length) {
      if (newValue.text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '') == rawText) {
        formattedText += '-';
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ValueNotifier<String> userId = useState('');
    ValueNotifier<bool> loading = useState(false);
    final usageState = ref.watch(usageProvider);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final controller = useTextEditingController();
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
                        color: AppTheme.primary.withAlpha((0.07 * 255).round()),
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
                        keyboardType: TextInputType.visiblePassword,
                        controller: controller,
                        inputFormatters: [
                          UserIdFormatter(),
                        ],
                        onChanged: (value) {
                          userId.value = value;
                        },
                        decoration: InputDecoration(
                          labelText: "Användar-ID",
                          hintText: "Format: 123-abc-456",
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
                          backgroundColor: AppTheme.background
                              .withAlpha((0.7 * 255).round()),
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
                                    const Duration(milliseconds: 500));
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
              color: Colors.white.withOpacity(0.10),
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
                    color: AppTheme.primary.withAlpha((0.9 * 255).round()),
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
