import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key, required this.localeController});

  final AppLocaleController localeController;

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  AppLanguage _selectedLanguage = AppLanguage.bangla;
  bool _isSaving = false;

  Future<void> _continue() async {
    if (_isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    await widget.localeController.chooseLanguage(_selectedLanguage);

    if (!mounted) {
      return;
    }

    context.go(AppRoutes.home);
  }

  void _selectLanguage(AppLanguage language) {
    if (_isSaving) {
      return;
    }

    setState(() => _selectedLanguage = language);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: EpColors.n50,
      body: Stack(
        children: [
          const _HeaderWash(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LogoMark(),
                  const SizedBox(height: 30),
                  Text(
                    l10n.languageSelectionTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: EpColors.n900,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.chooseLanguage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: EpColors.n600,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _LanguageOption(
                    title: l10n.banglaName,
                    subtitle: l10n.banglaLabel,
                    selected: _selectedLanguage == AppLanguage.bangla,
                    onTap: () => _selectLanguage(AppLanguage.bangla),
                  ),
                  const SizedBox(height: 14),
                  _LanguageOption(
                    title: l10n.englishName,
                    subtitle: l10n.englishLabel,
                    selected: _selectedLanguage == AppLanguage.english,
                    onTap: () => _selectLanguage(AppLanguage.english),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.languageCanChangeLater,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: EpColors.n500,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _isSaving ? null : _continue,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: EpColors.green500,
                      disabledBackgroundColor: EpColors.green200,
                      foregroundColor: EpColors.n0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text(l10n.continueLabel),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderWash extends StatelessWidget {
  const _HeaderWash();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: 270,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [EpColors.green50, Color(0x00EFFCEE)],
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 112,
        height: 112,
        padding: const EdgeInsets.all(16),
        child: Image.asset('assets/logo/e-pusti_logo.png', fit: BoxFit.contain),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? EpColors.green50 : EpColors.n0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? EpColors.green500 : EpColors.n200,
            width: selected ? 1.5 : 1,
          ),
        ),
        elevation: selected ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            height: 90,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: EpColors.n900,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: EpColors.n600,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: selected ? EpColors.green500 : EpColors.n0,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? EpColors.green500 : EpColors.n300,
                        width: 1.5,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 17, color: EpColors.n0)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
