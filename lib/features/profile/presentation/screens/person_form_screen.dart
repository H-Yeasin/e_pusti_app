import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/date_format.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/feedback/ep_state_view.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../bmi/domain/entities/bmi_models.dart';
import '../../../bmi/presentation/widgets/sex_label.dart';
import '../../domain/districts.dart';
import '../../domain/profile_models.dart';
import '../profile_labels.dart';
import '../profile_providers.dart';
import 'pickers.dart';

/// PRO-02: the holder form (district, occupation, life-stage toggles) or a
/// dependant form (relationship, with the reason for DOB and sex stated).
class PersonFormScreen extends ConsumerStatefulWidget {
  const PersonFormScreen({super.key, this.personId});

  /// Null for a new dependant.
  final String? personId;

  @override
  ConsumerState<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends ConsumerState<PersonFormScreen> {
  final _name = TextEditingController();
  Person? _draft;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Person? _initialPerson(List<Person> family) {
    if (widget.personId == null) {
      return Person(id: newId(), relationship: Relationship.child);
    }
    return family.where((p) => p.id == widget.personId).firstOrNull;
  }

  void _update(Person Function(Person) change) =>
      setState(() => _draft = change(_draft!));

  Future<void> _save() async {
    final consent = await ref.read(consentProvider.future);
    if (!mounted) return;
    if (!consent.hasAnswered) {
      context.push(
        AppRoutes.consentReturningTo(GoRouterState.of(context).uri.toString()),
      );
      return;
    }
    final name = _name.text.trim();
    var person = name.isEmpty
        ? _draft!.copyWith(clearName: true)
        : _draft!.copyWith(name: name);
    if (person.sex != Sex.female) {
      person = person.copyWith(pregnant: false, breastfeeding: false);
    }
    setState(() => _saving = true);
    try {
      await ref.read(familyProvider.notifier).save(person);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.savedToast)));
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.removeMemberConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: EpColors.destructiveFill,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(familyProvider.notifier).remove(_draft!.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final family = ref.watch(familyProvider);

    if (_draft == null && family.hasValue) {
      final initial = _initialPerson(family.value!);
      if (initial != null) {
        _draft = initial;
        _name.text = initial.name ?? '';
      }
    }
    final person = _draft;
    if (person == null) {
      return Scaffold(
        appBar: EpAppBar(title: l10n.profileTitle),
        body: family.isLoading
            ? const Center(child: CircularProgressIndicator())
            : EpStateView(
                icon: Icons.person_off_outlined,
                title: l10n.serverErrorTitle,
                body: '',
              ),
      );
    }

    final isNew = widget.personId == null;
    final holder = person.isHolder;
    final age = person.ageMonthsAt(DateTime.now());
    final district = districtById(person.districtId);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: EpAppBar(
        title: holder
            ? l10n.profileTitle
            : (isNew ? l10n.familyAddAction : personName(context, person)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(EpSpace.gutter),
        children: [
          TextField(
            key: const ValueKey('person-name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.fieldNameOptional,
              hintText: l10n.fieldNameHint,
              border: const OutlineInputBorder(borderRadius: EpRadius.mdAll),
            ),
          ),
          const SizedBox(height: EpSpace.s3),
          if (!holder)
            _PickerRow(
              key: const ValueKey('person-relationship'),
              label: l10n.fieldRelationship,
              value: relationshipLabel(context, person.relationship),
              onTap: () async {
                final r = await pickRelationship(context, person.relationship);
                if (r != null) _update((p) => p.copyWith(relationship: r));
              },
            ),
          _PickerRow(
            key: const ValueKey('person-dob'),
            label: l10n.fieldDob,
            value: person.dateOfBirth == null
                ? l10n.fieldChoose
                : _longDate(context, person.dateOfBirth!),
            onTap: () async {
              final d = await pickDateOfBirth(context, person.dateOfBirth);
              if (d != null) _update((p) => p.copyWith(dateOfBirth: d));
            },
          ),
          if (age != null)
            Padding(
              padding: const EdgeInsets.only(
                left: EpSpace.s4,
                bottom: EpSpace.s2,
              ),
              child: Text(
                l10n.dobSelectedAge(ageLabel(context, age)),
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (!holder)
            Padding(
              padding: const EdgeInsets.only(bottom: EpSpace.s2),
              child: EpBanner(
                tone: EpBannerTone.clinical,
                icon: Icons.info_outline_rounded,
                message: l10n.dobReason,
              ),
            ),
          _PickerRow(
            key: const ValueKey('person-sex'),
            label: l10n.bmiSex,
            value: person.sex == null
                ? l10n.fieldChoose
                : sexLabel(context, person.sex!),
            onTap: () async {
              final s = await pickSex(context, person.sex);
              if (s != null) _update((p) => p.copyWith(sex: s));
            },
          ),
          if (holder) ...[
            _PickerRow(
              key: const ValueKey('person-district'),
              label: l10n.fieldDistrict,
              value: district == null
                  ? l10n.fieldChoose
                  : districtLabel(context, district),
              onTap: () async {
                final d = await pickDistrict(context, person.districtId);
                if (d != null) _update((p) => p.copyWith(districtId: d));
              },
            ),
            _PickerRow(
              key: const ValueKey('person-occupation'),
              label: l10n.fieldOccupation,
              value: person.occupation == null
                  ? l10n.fieldChoose
                  : occupationLabel(context, person.occupation!),
              onTap: () async {
                final o = await pickOccupation(context, person.occupation);
                if (o != null) _update((p) => p.copyWith(occupation: o));
              },
            ),
            if (person.sex == Sex.female) ...[
              SwitchListTile(
                key: const ValueKey('person-pregnant'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: EpSpace.s4,
                ),
                title: Text(l10n.fieldPregnant),
                value: person.pregnant,
                onChanged: (v) => _update(
                  (p) => v
                      ? p.copyWith(pregnant: true)
                      : p.copyWith(pregnant: false, clearDueDate: true),
                ),
              ),
              if (person.pregnant)
                _PickerRow(
                  key: const ValueKey('person-due-date'),
                  label: l10n.fieldDueDate,
                  value: person.expectedDueDate == null
                      ? l10n.fieldChoose
                      : _longDate(context, person.expectedDueDate!),
                  onTap: () async {
                    final now = DateTime.now();
                    final d = await showDatePicker(
                      context: context,
                      initialDate:
                          person.expectedDueDate ??
                          now.add(const Duration(days: 140)),
                      firstDate: now.subtract(const Duration(days: 14)),
                      lastDate: now.add(const Duration(days: 294)),
                    );
                    if (d != null) {
                      _update((p) => p.copyWith(expectedDueDate: d));
                    }
                  },
                ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: EpSpace.s4,
                ),
                title: Text(l10n.fieldBreastfeeding),
                value: person.breastfeeding,
                onChanged: (v) => _update((p) => p.copyWith(breastfeeding: v)),
              ),
            ],
          ],
          _PickerRow(
            label: holder ? l10n.fieldInterests : l10n.fieldInterestsOptional,
            value: person.interests.isEmpty
                ? l10n.fieldChoose
                : l10n.fieldSelectedCount(
                    context.digits(person.interests.length),
                  ),
            onTap: () async {
              final i = await pickInterests(context, person.interests);
              if (i != null) _update((p) => p.copyWith(interests: i));
            },
          ),
          const SizedBox(height: EpSpace.s6),
          FilledButton(
            key: const ValueKey('person-save'),
            onPressed: _saving ? null : _save,
            child: Text(l10n.saveAction),
          ),
          if (!holder && !isNew) ...[
            const SizedBox(height: EpSpace.s2),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: EpColors.destructiveFill,
              ),
              onPressed: _remove,
              child: Text(l10n.removeMemberAction),
            ),
          ],
        ],
      ),
    );
  }

  static String _longDate(BuildContext context, DateTime d) =>
      '${formatShortDate(context, d)} ${context.digits(d.year)}';
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: EpSpace.s4),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(value, style: Theme.of(context).textTheme.titleMedium),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
