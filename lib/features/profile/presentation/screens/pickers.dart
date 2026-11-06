import 'package:flutter/material.dart';

import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../bmi/domain/entities/bmi_models.dart';
import '../../../bmi/presentation/widgets/sex_label.dart';
import '../../domain/districts.dart';
import '../../domain/profile_models.dart';
import '../profile_labels.dart';

Future<T?> _open<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

/// Single-choice list page with a check on the current value.
class _ChoicePage<T> extends StatelessWidget {
  const _ChoicePage({
    required this.title,
    required this.options,
    required this.label,
    required this.selected,
    this.footer,
  });

  final String title;
  final List<T> options;
  final String Function(T) label;
  final T? selected;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EpAppBar(title: title),
      body: ListView(
        children: [
          for (final option in options)
            ListTile(
              title: Text(label(option)),
              trailing: option == selected
                  ? const Icon(Icons.check_rounded, color: EpColors.fillPrimary)
                  : null,
              onTap: () => Navigator.of(context).pop(option),
            ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.all(EpSpace.gutter),
              child: footer,
            ),
        ],
      ),
    );
  }
}

/// PRO-04b.
Future<Occupation?> pickOccupation(BuildContext context, Occupation? current) =>
    _open(
      context,
      _ChoicePage<Occupation>(
        title: context.l10n.pickOccupationTitle,
        options: Occupation.values,
        label: (o) => occupationLabel(context, o),
        selected: current,
      ),
    );

/// PRO-04c (dependants only — the holder is fixed).
Future<Relationship?> pickRelationship(
  BuildContext context,
  Relationship? current,
) => _open(
  context,
  _ChoicePage<Relationship>(
    title: context.l10n.pickRelationshipTitle,
    options: Relationship.values
        .where((r) => r != Relationship.holder)
        .toList(),
    label: (r) => relationshipLabel(context, r),
    selected: current,
  ),
);

/// PRO-04d — states the BMI consequence of "Other".
Future<Sex?> pickSex(BuildContext context, Sex? current) => _open(
  context,
  _ChoicePage<Sex>(
    title: context.l10n.pickSexTitle,
    options: Sex.values,
    label: (s) => sexLabel(context, s),
    selected: current,
    footer: EpBanner(
      tone: EpBannerTone.clinical,
      icon: Icons.info_outline_rounded,
      message: context.l10n.bmiSexNote,
    ),
  ),
);

/// PRO-04a — 64 districts grouped by division, with search.
Future<String?> pickDistrict(BuildContext context, String? current) =>
    _open(context, _DistrictPage(current: current));

class _DistrictPage extends StatefulWidget {
  const _DistrictPage({required this.current});

  final String? current;

  @override
  State<_DistrictPage> createState() => _DistrictPageState();
}

class _DistrictPageState extends State<_DistrictPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = _query.trim().toLowerCase();
    final matches = districts
        .where(
          (d) =>
              q.isEmpty || d.bn.contains(q) || d.en.toLowerCase().contains(q),
        )
        .toList();

    return Scaffold(
      appBar: EpAppBar(title: l10n.pickDistrictTitle),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(EpSpace.gutter),
            child: TextField(
              key: const ValueKey('district-search'),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: l10n.pickDistrictSearch,
                filled: true,
                fillColor: EpColors.surface,
                border: const OutlineInputBorder(borderRadius: EpRadius.mdAll),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final division in Division.values)
                  if (matches.any((d) => d.division == division)) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        EpSpace.gutter,
                        EpSpace.s3,
                        EpSpace.gutter,
                        EpSpace.s1,
                      ),
                      child: Text(
                        divisionLabel(context, division),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    for (final d in matches.where(
                      (d) => d.division == division,
                    ))
                      ListTile(
                        title: Text(districtLabel(context, d)),
                        trailing: d.id == widget.current
                            ? const Icon(
                                Icons.check_rounded,
                                color: EpColors.fillPrimary,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(d.id),
                      ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// PRO-04e — multi-select with an explicit confirm.
Future<Set<Interest>?> pickInterests(
  BuildContext context,
  Set<Interest> current,
) => _open(context, _InterestsPage(initial: current));

class _InterestsPage extends StatefulWidget {
  const _InterestsPage({required this.initial});

  final Set<Interest> initial;

  @override
  State<_InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends State<_InterestsPage> {
  late final Set<Interest> _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: EpAppBar(title: l10n.fieldInterests),
      body: ListView(
        padding: const EdgeInsets.all(EpSpace.gutter),
        children: [
          Text(
            l10n.pickInterestsHint,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: EpSpace.s3),
          Wrap(
            spacing: EpSpace.s2,
            runSpacing: EpSpace.s2,
            children: [
              for (final interest in Interest.values)
                FilterChip(
                  label: Text(interestLabel(context, interest)),
                  selected: _selected.contains(interest),
                  onSelected: (on) => setState(
                    () => on
                        ? _selected.add(interest)
                        : _selected.remove(interest),
                  ),
                ),
            ],
          ),
          const SizedBox(height: EpSpace.s8),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            child: Text(
              l10n.pickInterestsDone(context.digits(_selected.length)),
            ),
          ),
        ],
      ),
    );
  }
}

/// PRO-04f — platform date picker, then the resulting age is shown on the
/// form.
Future<DateTime?> pickDateOfBirth(BuildContext context, DateTime? current) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: current ?? DateTime(now.year - 30, now.month, now.day),
    firstDate: DateTime(now.year - 110),
    lastDate: now,
    initialEntryMode: DatePickerEntryMode.calendarOnly,
  );
}
