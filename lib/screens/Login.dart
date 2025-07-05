import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:screen_time/api.dart' as api;
import 'package:screen_time/providers/user_provider.dart';
import 'package:screen_time/providers/usage_provider.dart';
import 'package:screen_time/screens/Usage.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ValueNotifier<String> userId = useState('');
    ValueNotifier<bool> loading = useState(false);
    final usageState = ref.watch(usageProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Skärmtidstracker"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Logga in med ditt Användar-ID",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16.0),
              TextField(
                onChanged: (value) {
                  userId.value = value;
                },
                decoration: const InputDecoration(
                  labelText: "Användar-ID",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: loading.value
                    ? null
                    : () async {
                        loading.value = true;
                        bool exists = await api.checkUserId(userId.value);
                        await Future.delayed(const Duration(seconds: 1));
                        if (exists) {
                          ref.read(userIdProvider.notifier).setUserId(userId.value);
                          if (!usageState.hasPermission && context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const UsagePage()),
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
                child: loading.value
                    ? const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                          ),
                        ),
                      )
                    : const Text("Logga in"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
