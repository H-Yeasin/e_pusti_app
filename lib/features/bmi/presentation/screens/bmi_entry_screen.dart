import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../profile/domain/profile_models.dart';
import '../../../profile/presentation/profile_labels.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../domain/bmi_engine.dart';
import '../../domain/entities/bmi_models.dart';
import '../bmi_route_args.dart';
import '../widgets/sex_label.dart';

enum _HeightUnit { cm, feetInches }

/// BMI-01. Anonymous: works without an account; saving needs login.
/// Logged in: "who is this for?" fills age and sex from the profile.
class BmiEntryScreen extends ConsumerStatefulWidget {
  const BmiEntryScreen({super.key, this.personId});

  final String? personId;

  @override
  ConsumerState<BmiEntryScreen> createState() => _BmiEntryScreenState();
}

class _BmiEntryScreenState extends ConsumerState<BmiEntryScreen> {
  final _cm = TextEditingController();
  final _feet = TextEditingController();
  final _inches = TextEditingController();
  final _kg = TextEditingController();
  _HeightUnit _unit = _HeightUnit.cm;
  int? _ageMonths;
  Sex? _sex;
  bool _submitted = false;
  String? _personId;
  bool _personApplied = false;

  void _selectPerson(Person person) {
    setState(() {
      _personId = person.id;
      _ageMonths = person.ageMonthsAt(DateTime.now());
      _sex = person.sex;
    });
  }

  @override
  void initState() {
    super.initState();
    for (final c in [_cm, _feet, _inches, _kg]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_cm, _feet, _inches, _kg]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _heightCm {
    if (_unit == _HeightUnit.cm) {
      return parseLocalizedNumber(_cm.text);
    }
    final feet = parseLocalizedNumber(_feet.text);
    final inches = parseLocalizedNumber(_inches.text) ?? 0;
    if (feet == null || inches < 0 || inches >= 12) {
      return null;
    }
    return feetInchesToCm(feet.truncate(), inches);
  }

  double? get _weightKg => parseLocalizedNumber(_kg.text);

  bool get _heightValid {
    final h = _heightCm;
    return h != null &&
        h >= BmiLimits.minHeightCm &&
        h <= BmiLimits.maxHeightCm;
  }

  bool get _weightValid {
    final w = _weightKg;
    return w != null &&
        w >= BmiLimits.minWeightKg &&
        w <= BmiLimits.maxWeightKg;
  }

  bool get _needsSex =>
      _ageMonths != null && _ageMonths! < BmiEngine.adultFromMonths;

  bool get _canSubmit =>
      _heightValid && _weightValid && (!_needsSex || _sex != null);

  void _submit() {
    setState(() => _submitted = true);
    if (!_canSubmit) {
      return;
    }
    final input = BmiInput(
      heightCm: _heightCm!,
      weightKg: _weightKg!,
      ageMonths: _ageMonths,
      sex: _needsSex ? _sex : null,
    );
    context.push(
      Uri(
        path: AppRoutes.bmiResult,
        queryParameters: BmiRouteArgs.toQuery(input, personId: _personId),
      ).toString(),
    );
  }

  Future<void> _pickAge() async {
    final picked = await showModalBottomSheet<_AgePick>(
      context: context,
      builder: (context) => _AgePickerSheet(initialMonths: _ageMonths),
    );
    if (picked != null) {
      setState(() => _ageMonths = picked.months);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final age = _ageMonths;
    final loggedIn = ref.watch(authControllerProvider).isLoggedIn;
    final family = loggedIn
        ? ref.watch(familyProvider).value ?? const <Person>[]
        : const <Person>[];
    if (!_personApplied && family.isNotEmpty) {
      _personApplied = true;
      final initial =
          family.where((p) => p.id == widget.personId).firstOrNull ??
          family.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _selectPerson(initial);
      });
    }

    return Scaffold(
      appBar: EpAppBar(title: l10n.homeBmiTitle),
      body: ListView(
        padding: const EdgeInsets.all(EpSpace.gutter),
        children: [
          if (!loggedIn)
            EpBanner(
              tone: EpBannerTone.clinical,
              icon: Icons.info_outline_rounded,
              message: l10n.bmiAnonymousNote,
            )
          else if (family.isNotEmpty) ...[
            Text(l10n.bmiForWhom, style: theme.textTheme.titleMedium),
            const SizedBox(height: EpSpace.s2),
            Wrap(
              key: const ValueKey('bmi-for-whom'),
              spacing: EpSpace.s2,
              runSpacing: EpSpace.s2,
              children: [
                for (final person in family)
                  ChoiceChip(
                    label: Text(
                      person.isHolder
                          ? l10n.relHolderYou(
                              person.name?.trim().isNotEmpty == true
                                  ? person.name!.trim()
                                  : l10n.youLabel,
                            )
                          : personName(context, person),
                    ),
                    selected: _personId == person.id,
                    onSelected: (_) => _selectPerson(person),
                  ),
              ],
            ),
          ],
          const SizedBox(height: EpSpace.s5),
          Row(
            children: [
              Expanded(
                child: Text(l10n.bmiHeight, style: theme.textTheme.titleMedium),
              ),
              SegmentedButton<_HeightUnit>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: _HeightUnit.cm,
                    label: Text(l10n.bmiUnitCm),
                  ),
                  ButtonSegment(
                    value: _HeightUnit.feetInches,
                    label: Text(l10n.bmiUnitFeetInches),
                  ),
                ],
                selected: {_unit},
                onSelectionChanged: (s) => setState(() => _unit = s.first),
              ),
            ],
          ),
          const SizedBox(height: EpSpace.s2),
          if (_unit == _HeightUnit.cm)
            _NumberField(
              key: const ValueKey('bmi-height-cm'),
              controller: _cm,
              suffix: l10n.bmiUnitCm,
              error: _submitted && !_heightValid ? l10n.bmiCheckHeight : null,
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _NumberField(
                    key: const ValueKey('bmi-height-ft'),
                    controller: _feet,
                    suffix: l10n.bmiFeet,
                    decimal: false,
                    error: _submitted && !_heightValid
                        ? l10n.bmiCheckHeight
                        : null,
                  ),
                ),
                const SizedBox(width: EpSpace.s3),
                Expanded(
                  child: _NumberField(
                    key: const ValueKey('bmi-height-in'),
                    controller: _inches,
                    suffix: l10n.bmiInches,
                  ),
                ),
              ],
            ),
          const SizedBox(height: EpSpace.s4),
          Text(l10n.bmiWeight, style: theme.textTheme.titleMedium),
          const SizedBox(height: EpSpace.s2),
          _NumberField(
            key: const ValueKey('bmi-weight'),
            controller: _kg,
            suffix: l10n.bmiKg,
            error: _submitted && !_weightValid ? l10n.bmiCheckWeight : null,
          ),
          const SizedBox(height: EpSpace.s4),
          Text(l10n.bmiAge, style: theme.textTheme.titleMedium),
          const SizedBox(height: EpSpace.s2),
          Material(
            color: EpColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: EpRadius.mdAll,
              side: BorderSide(color: EpColors.borderDefault),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              key: const ValueKey('bmi-age'),
              title: Text(
                age == null
                    ? l10n.bmiAddAgeOptional
                    : l10n.bmiAgeValue(
                        context.digits(age ~/ 12),
                        context.digits(age % 12),
                      ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _pickAge,
            ),
          ),
          const SizedBox(height: EpSpace.s2),
          if (age == null)
            Text(l10n.bmiNoAgeNote, style: theme.textTheme.bodySmall),
          if (_needsSex) ...[
            const SizedBox(height: EpSpace.s3),
            Text(l10n.bmiSex, style: theme.textTheme.titleMedium),
            const SizedBox(height: EpSpace.s2),
            SegmentedButton<Sex>(
              key: const ValueKey('bmi-sex'),
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: [
                for (final sex in Sex.values)
                  ButtonSegment(
                    value: sex,
                    label: Text(sexLabel(context, sex)),
                  ),
              ],
              selected: {?_sex},
              onSelectionChanged: (s) =>
                  setState(() => _sex = s.isEmpty ? null : s.first),
            ),
            const SizedBox(height: EpSpace.s2),
            Text(l10n.bmiSexNote, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: EpSpace.s8),
          FilledButton(
            onPressed: _canSubmit || !_submitted ? _submit : null,
            child: Text(l10n.bmiShowResult),
          ),
          if (loggedIn) ...[
            const SizedBox(height: EpSpace.s2),
            TextButton(
              onPressed: () => context.push(
                Uri(
                  path: AppRoutes.bmiHistory,
                  queryParameters: {'p': ?_personId},
                ).toString(),
              ),
              child: Text(l10n.bmiSeeHistory),
            ),
          ],
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    super.key,
    required this.controller,
    required this.suffix,
    this.error,
    this.decimal = true,
  });

  final TextEditingController controller;
  final String suffix;
  final String? error;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      style: const TextStyle(
        fontSize: EpTextSize.bodyLarge,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        suffixText: suffix,
        errorText: error,
        filled: true,
        fillColor: EpColors.surface,
        border: const OutlineInputBorder(borderRadius: EpRadius.mdAll),
      ),
    );
  }
}

class _AgePick {
  const _AgePick(this.months);

  final int? months;
}

class _AgePickerSheet extends StatefulWidget {
  const _AgePickerSheet({required this.initialMonths});

  final int? initialMonths;

  @override
  State<_AgePickerSheet> createState() => _AgePickerSheetState();
}

class _AgePickerSheetState extends State<_AgePickerSheet> {
  late int _years = (widget.initialMonths ?? 30 * 12) ~/ 12;
  late int _months = (widget.initialMonths ?? 0) % 12;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    DropdownMenuItem<int> item(int v) =>
        DropdownMenuItem(value: v, child: Text(context.digits(v)));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          EpSpace.s6,
          0,
          EpSpace.s6,
          EpSpace.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.bmiAge, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: EpSpace.s4),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: const ValueKey('bmi-age-years'),
                    initialValue: _years,
                    decoration: InputDecoration(labelText: l10n.bmiAgeYears),
                    items: [for (var y = 0; y <= 110; y++) item(y)],
                    onChanged: (v) => setState(() => _years = v ?? _years),
                  ),
                ),
                const SizedBox(width: EpSpace.s3),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: const ValueKey('bmi-age-months'),
                    initialValue: _months,
                    decoration: InputDecoration(labelText: l10n.bmiAgeMonths),
                    items: [for (var m = 0; m < 12; m++) item(m)],
                    onChanged: (v) => setState(() => _months = v ?? _months),
                  ),
                ),
              ],
            ),
            const SizedBox(height: EpSpace.s6),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(_AgePick(_years * 12 + _months)),
              child: Text(l10n.doneAction),
            ),
            if (widget.initialMonths != null)
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(const _AgePick(null)),
                child: Text(l10n.bmiAgeClear),
              ),
          ],
        ),
      ),
    );
  }
}
