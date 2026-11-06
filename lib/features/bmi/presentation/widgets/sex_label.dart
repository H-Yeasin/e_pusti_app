import 'package:flutter/widgets.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/bmi_models.dart';

String sexLabel(BuildContext context, Sex sex) {
  final l10n = context.l10n;
  return switch (sex) {
    Sex.female => l10n.sexFemale,
    Sex.male => l10n.sexMale,
    Sex.other => l10n.sexOther,
  };
}

/// "boy" / "girl" for child results.
String childGroupLabel(BuildContext context, Sex sex) {
  final l10n = context.l10n;
  return sex == Sex.female ? l10n.childGirl : l10n.childBoy;
}
