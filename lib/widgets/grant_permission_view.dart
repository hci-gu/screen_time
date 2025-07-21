import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/usage_provider.dart';
import 'package:screen_time/theme/app_theme.dart';

class GrantPermissionView extends ConsumerWidget {
  const GrantPermissionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageNotifier = ref.read(usageProvider.notifier);
    return Center(
      child: Padding(
        padding: AppTheme.elementPadding,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.privacy_tip_rounded,
                  size: 56, color: AppTheme.primary),
              AppTheme.spacer,
              Text(
                'Ge åtkomst till användarspårning',
                style: AppTheme.headLine2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                'För att appen ska kunna logga din skärmtid behöver du ge åtkomst till användarspårning i inställningarna.',
                style: AppTheme.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Öppna inställningar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  usageNotifier.requestUsageStatsPermission();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
