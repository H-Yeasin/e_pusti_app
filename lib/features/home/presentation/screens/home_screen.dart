import 'package:flutter/material.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/localization/localization.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.environment});

  final AppEnvironment environment;

  static const _adSlots = [
    _DashboardSlot.empty(id: 'home-top'),
    _DashboardSlot.empty(id: 'after-sms'),
    _DashboardSlot.empty(id: 'after-actions'),
    _DashboardSlot.empty(id: 'after-bmi'),
    _DashboardSlot.empty(id: 'feed-1'),
    _DashboardSlot.empty(id: 'feed-2'),
    _DashboardSlot.empty(id: 'feed-3'),
    _DashboardSlot.empty(id: 'feed-bottom'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final navigationTiles = [
      _HomeAction(
        label: l10n.homeWebinar,
        iconAsset: 'assets/icons/webinar.gif',
        color: const Color(0xFF008C44),
      ),
      _HomeAction(
        label: l10n.homeCourse,
        iconAsset: 'assets/icons/course.gif',
        color: const Color(0xFFCE8A00),
      ),
      _HomeAction(
        label: l10n.homeDigiSkill,
        iconAsset: 'assets/icons/digiskill.gif',
        color: const Color(0xFF1E5AA8),
      ),
      _HomeAction(
        label: l10n.homeLibrary,
        iconAsset: 'assets/icons/library.gif',
        color: const Color(0xFF6F3DB8),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F4),
      drawer: Drawer(
        child: SafeArea(
          child: ListTile(
            leading: const Icon(Icons.eco_outlined),
            title: Text(l10n.homeAppTitle),
            subtitle: Text(l10n.runningEnvironment(environment.label)),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00AE22),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          l10n.homeAppTitle,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 52,
        actions: const [SizedBox(width: 48)],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 460 ? 420.0 : double.infinity;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SlotBanner(slot: _adSlots[0]),
                      _SmsSubscriptionCard(l10n: l10n),
                      const _SlotBanner(slot: _adSlots[1]),
                      const SizedBox(height: 12),
                      _ActionGrid(actions: navigationTiles),
                      const _SlotBanner(slot: _adSlots[2]),
                      const SizedBox(height: 12),
                      _BmiCard(l10n: l10n),
                      const _SlotBanner(slot: _adSlots[3]),
                      _HomeFeed(l10n: l10n),
                      const _SlotBanner(slot: _adSlots[4]),
                      const _SlotBanner(slot: _adSlots[5]),
                      const _SlotBanner(slot: _adSlots[6]),
                      const _SlotBanner(slot: _adSlots[7]),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SmsSubscriptionCard extends StatelessWidget {
  const _SmsSubscriptionCard({required this.l10n});

  final EPustiGeneratedLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _PromoCard(
      backgroundColor: const Color(0xFFE5F1EF),
      titleColor: const Color(0xFF008C44),
      buttonColor: const Color(0xFF00A83C),
      title: l10n.homeSmsTitle,
      subtitle: l10n.homeSmsSubtitle,
      buttonLabel: l10n.homeSubscribeButton,
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.l10n});

  final EPustiGeneratedLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _PromoCard(
      backgroundColor: const Color(0xFFFFF4DC),
      titleColor: const Color(0xFFA87915),
      buttonColor: const Color(0xFFE19A00),
      title: l10n.homeBmiTitle,
      subtitle: l10n.homeBmiSubtitle,
      buttonLabel: l10n.homeViewNowButton,
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.backgroundColor,
    required this.titleColor,
    required this.buttonColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
  });

  final Color backgroundColor;
  final Color titleColor;
  final Color buttonColor;
  final String title;
  final String subtitle;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.48),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            onPressed: () {},
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<_HomeAction> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) => _ActionTile(action: actions[index]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final _HomeAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: () {},
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFFE1E3DD)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                action.iconAsset,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                color: action.color,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.apps_rounded, color: action.color, size: 24);
                },
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF151515),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeFeed extends StatelessWidget {
  const _HomeFeed({required this.l10n});

  final EPustiGeneratedLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        _InsightTile(
          icon: Icons.restaurant_menu_rounded,
          title: l10n.homeNutritionTipTitle,
          subtitle: l10n.homeNutritionTipSubtitle,
        ),
        const SizedBox(height: 10),
        _InsightTile(
          icon: Icons.health_and_safety_outlined,
          title: l10n.homeHealthCheckTitle,
          subtitle: l10n.homeHealthCheckSubtitle,
        ),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: const BorderSide(color: Color(0xFFE1E3DD)),
      ),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFE7F6EA),
        child: Icon(icon, color: const Color(0xFF008C44), size: 20),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.48),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SlotBanner extends StatelessWidget {
  const _SlotBanner({required this.slot});

  final _DashboardSlot slot;

  @override
  Widget build(BuildContext context) {
    final assetPath = slot.assetPath;
    if (assetPath == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: AspectRatio(
          aspectRatio: 3.45,
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _HomeAction {
  const _HomeAction({
    required this.label,
    required this.iconAsset,
    required this.color,
  });

  final String label;
  final String iconAsset;
  final Color color;
}

class _DashboardSlot {
  const _DashboardSlot({required this.id, required this.assetPath});

  const _DashboardSlot.empty({required String id}) : this(id: id, assetPath: null);

  final String id;
  final String? assetPath;
}