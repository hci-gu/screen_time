import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:screen_time/api.dart' as api;
import 'package:screen_time/providers/user_provider.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ValueNotifier<String> userId = useState('');
    ValueNotifier<bool> loading = useState(false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Screen time tracker"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Login Page"),
              const SizedBox(height: 16.0),
              TextField(
                onChanged: (value) {
                  userId.value = value;
                },
                decoration: const InputDecoration(
                  labelText: "User ID",
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
                          ref
                              .read(userIdProvider.notifier)
                              .setUserId(userId.value);
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("User ID does not exist"),
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
                    : const Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
