import 'package:flutter/widgets.dart';

import '../../../core/localization/digits.dart';
import '../../../core/localization/localization.dart';
import '../../bmi/presentation/widgets/sex_label.dart';
import '../domain/districts.dart';
import '../domain/profile_models.dart';

String relationshipLabel(BuildContext context, Relationship r) {
  final l10n = context.l10n;
  return switch (r) {
    Relationship.holder => l10n.youLabel,
    Relationship.child => l10n.relChild,
    Relationship.spouse => l10n.relSpouse,
    Relationship.parent => l10n.relParent,
    Relationship.sibling => l10n.relSibling,
    Relationship.other => l10n.relOther,
  };
}

String occupationLabel(BuildContext context, Occupation o) {
  final l10n = context.l10n;
  return switch (o) {
    Occupation.student => l10n.occStudent,
    Occupation.privateEmployee => l10n.occPrivate,
    Occupation.governmentEmployee => l10n.occGovernment,
    Occupation.business => l10n.occBusiness,
    Occupation.teacher => l10n.occTeacher,
    Occupation.farmer => l10n.occFarmer,
    Occupation.homemaker => l10n.occHomemaker,
    Occupation.other => l10n.occOther,
  };
}

String interestLabel(BuildContext context, Interest i) {
  final l10n = context.l10n;
  return switch (i) {
    Interest.balancedDiet => l10n.intBalanced,
    Interest.pregnancyNutrition => l10n.intPregnancy,
    Interest.weightManagement => l10n.intWeight,
    Interest.childNutrition => l10n.intChild,
    Interest.diabetesManagement => l10n.intDiabetes,
    Interest.generalHealth => l10n.intGeneral,
  };
}

String divisionLabel(BuildContext context, Division d) {
  final l10n = context.l10n;
  return switch (d) {
    Division.dhaka => l10n.divisionDhaka,
    Division.chattogram => l10n.divisionChattogram,
    Division.rajshahi => l10n.divisionRajshahi,
    Division.khulna => l10n.divisionKhulna,
    Division.barishal => l10n.divisionBarishal,
    Division.sylhet => l10n.divisionSylhet,
    Division.rangpur => l10n.divisionRangpur,
    Division.mymensingh => l10n.divisionMymensingh,
  };
}

String districtLabel(BuildContext context, District d) =>
    Localizations.localeOf(context).languageCode == 'bn' ? d.bn : d.en;

/// "9 y 4 m" under 19, "34 years" for adults.
String ageLabel(BuildContext context, int months) {
  final l10n = context.l10n;
  if (months < 19 * 12) {
    return l10n.ageYearsMonths(
      context.digits(months ~/ 12),
      context.digits(months % 12),
    );
  }
  return l10n.ageYears(context.digits(months ~/ 12));
}

/// Display name, falling back to the relationship.
String personName(BuildContext context, Person p) =>
    (p.name?.trim().isNotEmpty ?? false)
    ? p.name!.trim()
    : relationshipLabel(context, p.relationship);

/// "34 years · Female · Dhaka" style summary.
String personSummary(
  BuildContext context,
  Person p, {
  bool withRelation = false,
}) {
  final parts = <String>[];
  final age = p.ageMonthsAt(DateTime.now());
  if (age != null) parts.add(ageLabel(context, age));
  if (p.sex != null) parts.add(sexLabel(context, p.sex!));
  if (withRelation && !p.isHolder) {
    parts.add(relationshipLabel(context, p.relationship));
  }
  final district = districtById(p.districtId);
  if (p.isHolder && district != null) {
    parts.add(districtLabel(context, district));
  }
  return parts.join(' · ');
}
