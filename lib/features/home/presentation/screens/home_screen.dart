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

  static const _bottomBanners = [
    'assets/slot_banner/super-bundle-pack.jpeg',
    'assets/slot_banner/min-pack.jpeg',
    'assets/slot_banner/ratecutter.jpeg',
    'assets/slot_banner/super-bundle.jpeg',
    'assets/slot_banner/super-internet.jpeg',
    'assets/slot_banner/super-rate-cutter.jpeg',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final navigationTiles = [
      _HomeAction(
        label: l10n.homeWebinar,
        iconAsset: 'assets/icons/webinar.gif',
      ),
      _HomeAction(label: l10n.homeCourse, iconAsset: 'assets/icons/course.gif'),
      _HomeAction(
        label: l10n.homeDigiSkill,
        iconAsset: 'assets/icons/digiskill.gif',
      ),
      _HomeAction(
        label: l10n.homeLibrary,
        iconAsset: 'assets/icons/library.gif',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF6),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListTile(
            leading: const Icon(Icons.eco_outlined),
            title: Text(l10n.homeAppTitle),
            subtitle: Text(l10n.runningEnvironment(environment.label)),
          ),
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF118514),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Image.asset(
          'assets/logo/Header_logo.png',
          height: 40,
          fit: BoxFit.contain,
          semanticLabel: l10n.homeAppTitle,
        ),
        leading: const SizedBox(width: 48),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                icon: const Icon(Icons.menu_rounded, size: 28),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 50,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 460
                ? 420.0
                : double.infinity;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SlotBanner(slot: _adSlots[0]),
                      _SmsSubscriptionCard(l10n: l10n),
                      _SlotBanner(slot: _adSlots[1]),
                      const SizedBox(height: 30),
                      _ActionGrid(actions: navigationTiles),
                      _SlotBanner(slot: _adSlots[2]),
                      const SizedBox(height: 4),
                      _BmiCard(l10n: l10n),
                      _SlotBanner(slot: _adSlots[3]),
                      const SizedBox(height: 32),
                      const _BottomBannerCarousel(banners: _bottomBanners),
                      _SlotBanner(slot: _adSlots[4]),
                      _SlotBanner(slot: _adSlots[5]),
                      _SlotBanner(slot: _adSlots[6]),
                      _SlotBanner(slot: _adSlots[7]),
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
      backgroundColor: const Color(0xFFF0FFF1),
      borderColor: const Color(0xFFA9E9B5),
      titleColor: const Color(0xFF115C18),
      subtitleColor: const Color(0xFF66706A),
      buttonColor: const Color(0xFF118514),
      title: l10n.homeSmsTitle,
      subtitle: l10n.homeSmsSubtitle,
      buttonLabel: l10n.homeSubscribeButton,
      buttonStyle: _PromoButtonStyle.filled,
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.l10n});

  final EPustiGeneratedLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _PromoCard(
      backgroundColor: const Color(0xFFF1FAFF),
      borderColor: const Color(0xFFD8E8EF),
      titleColor: const Color(0xFF486473),
      subtitleColor: const Color(0xFF6D8490),
      buttonColor: const Color(0xFF547C91),
      title: l10n.homeBmiTitle,
      subtitle: l10n.homeBmiSubtitle,
      buttonLabel: l10n.homeViewNowButton,
      buttonStyle: _PromoButtonStyle.outlined,
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.backgroundColor,
    required this.borderColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.buttonColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonStyle,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color buttonColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final _PromoButtonStyle buttonStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            subtitle,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _PromoButton(
            label: buttonLabel,
            color: buttonColor,
            style: buttonStyle,
          ),
        ],
      ),
    );
  }
}

class _PromoButton extends StatelessWidget {
  const _PromoButton({
    required this.label,
    required this.color,
    required this.style,
  });

  final String label;
  final Color color;
  final _PromoButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    final textStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
    );

    if (style == _PromoButtonStyle.outlined) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(114, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: color),
          shape: shape,
          textStyle: textStyle,
        ),
        onPressed: () {},
        child: Text(label),
      );
    }

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(128, 46),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: shape,
        textStyle: textStyle,
      ),
      onPressed: () {},
      child: Text(label),
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
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.62,
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
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC9CEC7)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                action.iconAsset,
                width: 46,
                height: 46,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.apps_rounded,
                    color: Color(0xFF174A9B),
                    size: 46,
                  );
                },
              ),
              const SizedBox(height: 5),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF252725),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBannerCarousel extends StatelessWidget {
  const _BottomBannerCarousel({required this.banners});

  final List<String> banners;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: banners.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return _BottomBanner(assetPath: banners[index]);
        },
      ),
    );
  }
}

class _BottomBanner extends StatelessWidget {
  const _BottomBanner({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF222222)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
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
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 3.45,
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _HomeAction {
  const _HomeAction({required this.label, required this.iconAsset});

  final String label;
  final String iconAsset;
}

class _DashboardSlot {
  const _DashboardSlot({required this.id, required this.assetPath});

  const _DashboardSlot.empty({required String id})
    : this(id: id, assetPath: null);

  final String id;
  final String? assetPath;
}

enum _PromoButtonStyle { filled, outlined }
