import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_async_view.dart';
import '../../../../core/widgets/feedback/ep_state_view.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';

class Pust9Tip {
  const Pust9Tip({required this.day, required this.text});

  final int day;
  final String text;
}

/// Source of the PUST9 daily tips. No tip content is available to the app
/// yet, so the fixture is empty and the screen shows its empty state.
abstract interface class Pust9TipsRepository {
  Future<List<Pust9Tip>> fetchTips();
}

class EmptyPust9TipsRepository implements Pust9TipsRepository {
  const EmptyPust9TipsRepository();

  @override
  Future<List<Pust9Tip>> fetchTips() async => const [];
}

final pust9TipsRepositoryProvider = Provider<Pust9TipsRepository>(
  (ref) => const EmptyPust9TipsRepository(),
);

final pust9TipsProvider = FutureProvider<List<Pust9Tip>>(
  (ref) => ref.watch(pust9TipsRepositoryProvider).fetchTips(),
);

/// SMS-02 (P1-1): every tip readable in the app, even after the SMS is
/// deleted.
class Pust9ArchiveScreen extends ConsumerWidget {
  const Pust9ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tips = ref.watch(pust9TipsProvider);

    return Scaffold(
      appBar: EpAppBar(title: l10n.pust9ArchiveTitle),
      body: EpAsyncView(
        value: tips,
        onRetry: () => ref.invalidate(pust9TipsProvider),
        data: (items) {
          if (items.isEmpty) {
            return EpStateView(
              key: const ValueKey('pust9-archive-empty'),
              icon: Icons.sms_outlined,
              title: l10n.pust9ArchiveEmptyTitle,
              body: l10n.pust9ArchiveEmptyBody,
            );
          }
          final sorted = [...items]..sort((a, b) => b.day.compareTo(a.day));
          return ListView.separated(
            padding: const EdgeInsets.all(EpSpace.gutter),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: EpSpace.s2),
            itemBuilder: (context, i) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: EpColors.green50,
                  foregroundColor: EpColors.green800,
                  child: Text(context.digits(sorted[i].day)),
                ),
                title: Text(l10n.pust9TipDay(context.digits(sorted[i].day))),
                subtitle: Text(sorted[i].text),
              ),
            ),
          );
        },
      ),
    );
  }
}
