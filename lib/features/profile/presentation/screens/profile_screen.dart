import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_async_view.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../domain/profile_models.dart';
import '../profile_labels.dart';
import '../profile_providers.dart';

/// PRO-01. One adult account holder; dependants sit beneath.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final family = ref.watch(familyProvider);
    final consent = ref.watch(consentProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: EpAppBar(title: l10n.menuFamilyProfile),
      body: EpAsyncView(
        value: family,
        onRetry: () => ref.invalidate(familyProvider),
        data: (people) {
          final holder = people.where((p) => p.isHolder).firstOrNull;
          final dependants = people.where((p) => !p.isHolder).toList();
          return ListView(
            padding: const EdgeInsets.all(EpSpace.gutter),
            children: [
              if (consent != null && !consent.hasAnswered) ...[
                EpBanner(
                  key: const ValueKey('profile-consent-banner'),
                  icon: Icons.privacy_tip_outlined,
                  message: l10n.consentNeededBanner,
                  action: TextButton(
                    onPressed: () => context.push(
                      AppRoutes.consentReturningTo(AppRoutes.profile),
                    ),
                    child: Text(l10n.privacyGiveConsent),
                  ),
                ),
                const SizedBox(height: EpSpace.s4),
              ],
              Text(l10n.profileTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: EpSpace.s2),
              if (holder != null) _HolderCard(holder: holder),
              const SizedBox(height: EpSpace.s6),
              if (dependants.isEmpty)
                _AddFamilyCard(onAdd: () => context.push(AppRoutes.newPerson))
              else ...[
                Text(
                  l10n.familyCount(context.digits(dependants.length)),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: EpSpace.s2),
                for (final person in dependants)
                  Card(
                    margin: const EdgeInsets.only(bottom: EpSpace.s2),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: _Avatar(person: person),
                      title: Text(personName(context, person)),
                      subtitle: Text(
                        personSummary(context, person, withRelation: true),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(AppRoutes.person(person.id)),
                    ),
                  ),
                const SizedBox(height: EpSpace.s2),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.newPerson),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.familyAddAction),
                ),
              ],
              const SizedBox(height: EpSpace.s4),
              TextButton.icon(
                onPressed: () => context.push(AppRoutes.bmiHistory),
                icon: const Icon(Icons.monitor_weight_outlined),
                label: Text(l10n.bmiSeeHistory),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final name = personName(context, person);
    return CircleAvatar(
      backgroundColor: EpColors.green100,
      foregroundColor: EpColors.green800,
      child: Text(name.characters.first),
    );
  }
}

class _HolderCard extends StatelessWidget {
  const _HolderCard({required this.holder});

  final Person holder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasName = holder.name?.trim().isNotEmpty ?? false;
    final summary = personSummary(context, holder);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: const ValueKey('profile-holder'),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: EpSpace.s4,
          vertical: EpSpace.s2,
        ),
        leading: _Avatar(person: holder),
        title: Text(
          hasName ? holder.name!.trim() : l10n.profileAddName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: summary.isEmpty ? null : Text(summary),
        trailing: TextButton(
          onPressed: () => context.push(AppRoutes.person(holder.id)),
          child: Text(l10n.editAction),
        ),
      ),
    );
  }
}

class _AddFamilyCard extends StatelessWidget {
  const _AddFamilyCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: const ValueKey('profile-add-family'),
      padding: const EdgeInsets.all(EpSpace.cardPadding),
      decoration: BoxDecoration(
        color: EpColors.green50,
        borderRadius: EpRadius.mdAll,
        border: Border.all(color: EpColors.green200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.family_restroom_outlined,
                color: EpColors.green800,
              ),
              const SizedBox(width: EpSpace.s2),
              Expanded(
                child: Text(
                  l10n.familyAddTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: EpSpace.s2),
          Text(l10n.familyAddBody),
          const SizedBox(height: EpSpace.s3),
          FilledButton(onPressed: onAdd, child: Text(l10n.familyAddAction)),
        ],
      ),
    );
  }
}
