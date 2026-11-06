import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/config/remote_config.dart';
import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/commercial/ad_slot.dart';
import '../../../../core/widgets/display/ep_promo_card.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/widgets/login_prompt_sheet.dart';
import '../widgets/app_sidebar.dart';

/// HOM-01. Identical logged in or out; with the slot empty (the launch state)
/// the layout still looks finished.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pust9 = ref.watch(remoteConfigProvider.select((c) => c.pust9));

    void open(String route) {
      if (route == AppRoutes.home) {
        return;
      }
      final loggedIn = ref.read(authControllerProvider).isLoggedIn;
      if (AppRoutes.isGated(route) && !loggedIn) {
        showLoginPrompt(context, returnTo: route);
        return;
      }
      context.push(route);
    }

    final tiles = [
      _HomeTile(
        label: l10n.homeWebinar,
        iconAsset: 'assets/icons/webinar.gif',
        fallbackIcon: Icons.play_circle_outline_rounded,
        route: AppRoutes.webinars,
      ),
      _HomeTile(
        label: l10n.homeCourse,
        iconAsset: 'assets/icons/course.gif',
        fallbackIcon: Icons.menu_book_outlined,
        route: AppRoutes.courses,
      ),
      _HomeTile(
        label: l10n.homeDigiSkill,
        iconAsset: 'assets/icons/digiskill.gif',
        fallbackIcon: Icons.auto_awesome_outlined,
        route: AppRoutes.digiSkills,
      ),
      _HomeTile(
        label: l10n.homeLibrary,
        iconAsset: 'assets/icons/library.gif',
        fallbackIcon: Icons.local_library_outlined,
        route: AppRoutes.library,
      ),
    ];

    return Scaffold(
      endDrawer: AppSidebar(onNavigate: open),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/logo/Header_logo.png',
          height: 36,
          fit: BoxFit.contain,
          semanticLabel: l10n.homeAppTitle,
          errorBuilder: (context, error, stackTrace) => Text(l10n.homeAppTitle),
        ),
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
          const SizedBox(width: EpSpace.s1),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 460
                ? 420.0
                : double.infinity;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                EpSpace.gutter,
                EpSpace.s5,
                EpSpace.gutter,
                EpSpace.s6,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EpPromoCard(
                        key: const ValueKey('home-pust9-card'),
                        title: l10n.homeSmsTitle,
                        subtitle: l10n.homeSmsSubtitle(
                          context.digits(pust9.courseDays),
                        ),
                        actionLabel: l10n.homeSubscribeButton,
                        onAction: () => open(AppRoutes.pust9),
                      ),
                      const SizedBox(height: EpSpace.s5),
                      _TileGrid(tiles: tiles, onOpen: open),
                      const SizedBox(height: EpSpace.s5),
                      EpPromoCard(
                        key: const ValueKey('home-bmi-card'),
                        tone: EpCardTone.clinical,
                        title: l10n.homeBmiTitle,
                        subtitle: l10n.homeBmiSubtitle,
                        actionLabel: l10n.homeViewNowButton,
                        onAction: () => open(AppRoutes.bmi),
                      ),
                      AdSlot(
                        id: AdSlotId.homeBanner,
                        houseBuilder: (context, promotion) =>
                            switch (promotion) {
                              HousePromotion.pust9 => EpPromoCard(
                                title: l10n.homeSmsTitle,
                                subtitle: l10n.homeSmsSubtitle(
                                  context.digits(pust9.courseDays),
                                ),
                                actionLabel: l10n.homeSubscribeButton,
                                onAction: () => open(AppRoutes.pust9),
                              ),
                            },
                      ),
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

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles, required this.onOpen});

  final List<_HomeTile> tiles;
  final void Function(String route) onOpen;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: tiles.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: EpSpace.s3,
        crossAxisSpacing: EpSpace.s3,
        childAspectRatio: 1.62,
      ),
      itemBuilder: (context, index) {
        final tile = tiles[index];
        return _TileButton(tile: tile, onTap: () => onOpen(tile.route));
      },
    );
  }
}

class _TileButton extends StatelessWidget {
  const _TileButton({required this.tile, required this.onTap});

  final _HomeTile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EpColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: EpRadius.mdAll,
        side: BorderSide(color: EpColors.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              tile.iconAsset,
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stackTrace) => Icon(
                tile.fallbackIcon,
                color: EpColors.fillPrimary,
                size: 40,
              ),
            ),
            const SizedBox(height: EpSpace.s1),
            Text(
              tile.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: EpColors.textPrimary,
                fontSize: EpTextSize.body,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile {
  const _HomeTile({
    required this.label,
    required this.iconAsset,
    required this.fallbackIcon,
    required this.route,
  });

  final String label;
  final String iconAsset;
  final IconData fallbackIcon;
  final String route;
}
