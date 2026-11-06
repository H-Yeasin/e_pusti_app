import 'package:flutter/material.dart';
import '../../../share/share_actions.dart';
import '../../../search/search_index.dart';
import '../../../bookmarks/bookmarks.dart';
import '../../../../core/widgets/content/listen_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/ep_async_view.dart';
import '../../../../core/widgets/feedback/ep_banner.dart';
import '../../../../core/widgets/navigation/ep_app_bar.dart';
import '../../../../app/router/app_routes.dart';
import '../../../assessment/data/fixture_assessments.dart';
import '../../../assessment/domain/learning_models.dart';
import '../../../assessment/presentation/learning_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/widgets/login_prompt_sheet.dart';
import '../../../support/presentation/app_settings_controller.dart';
import '../../domain/course_models.dart';
import '../course_providers.dart';

/// CRS-02. Video size is shown before playback; a failed video never blocks
/// reading the text.
class ChapterScreen extends ConsumerStatefulWidget {
  const ChapterScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  ConsumerState<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends ConsumerState<ChapterScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the text counts as read for the offline summary, and as
    // started for a logged-in user's progress.
    ref.read(readChaptersProvider.notifier).markRead(widget.chapterId);
    if (ref.read(authControllerProvider).isLoggedIn) {
      ref
          .read(progressProvider.notifier)
          .markStarted(LearningItemType.chapter, widget.chapterId);
    }
  }

  String? get _assessmentId => chapterAssessments[widget.chapterId];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chapter = ref.watch(chapterProvider(widget.chapterId));
    final title = chapter.value == null
        ? l10n.academyTitle
        : l10n.chapterNumbered(
            context.digits(chapter.value!.summary.number),
            chapter.value!.summary.title,
          );

    return Scaffold(
      appBar: EpAppBar(
        title: title,
        actions: [
          if (chapter.value case final c?) ...[
            BookmarkButton(
              kind: SearchKind.chapter,
              id: c.summary.id,
              title: c.summary.title,
              route: AppRoutes.chapter(c.summary.id),
            ),
            IconButton(
              tooltip: l10n.shareAction,
              icon: const Icon(Icons.share_outlined),
              onPressed: () => shareInAppLink(
                context,
                ref,
                title: c.summary.title,
                route: AppRoutes.chapter(c.summary.id),
              ),
            ),
          ],
        ],
      ),
      body: EpAsyncView(
        value: chapter,
        onRetry: () => ref.invalidate(chapterProvider(widget.chapterId)),
        data: (data) => ListView(
          padding: const EdgeInsets.all(EpSpace.gutter),
          children: [
            ListenButton(parts: [data.summary.title, ...data.paragraphs]),
            const SizedBox(height: EpSpace.s4),
            if (data.video != null) ...[
              _VideoGate(video: data.video!),
              const SizedBox(height: EpSpace.s5),
            ],
            for (final paragraph in data.paragraphs) ...[
              Text(paragraph, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: EpSpace.s4),
            ],
            const SizedBox(height: EpSpace.s4),
            if (_assessmentId != null)
              FilledButton(
                onPressed: () => _takeQuiz(context),
                child: Text(l10n.takeQuizAction),
              ),
          ],
        ),
      ),
    );
  }

  void _takeQuiz(BuildContext context) {
    final l10n = context.l10n;
    if (!ref.read(authControllerProvider).isLoggedIn) {
      showLoginPrompt(
        context,
        returnTo: GoRouterState.of(context).uri.toString(),
        body: l10n.quizLoginBody,
      );
      return;
    }
    context.push(AppRoutes.assessment(_assessmentId!));
  }
}

enum _VideoState { idle, failed }

class _VideoGate extends ConsumerStatefulWidget {
  const _VideoGate({required this.video});

  final ChapterVideo video;

  @override
  ConsumerState<_VideoGate> createState() => _VideoGateState();
}

class _VideoGateState extends ConsumerState<_VideoGate> {
  _VideoState _state = _VideoState.idle;

  void _play() {
    // A player is attached once chapters carry stream URLs; until then a
    // missing source is reported as the design's failed state.
    if (widget.video.url == null) {
      setState(() => _state = _VideoState.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wifiOnly =
        ref.watch(appSettingsProvider).value?.videoOnWifiOnly ?? true;
    final onWifi = ref.watch(isOnWifiProvider).value ?? false;
    final blockedByWifiSetting = wifiOnly && !onWifi;
    final size = context.digits(widget.video.sizeMb.round());

    if (_state == _VideoState.failed) {
      return Container(
        key: const ValueKey('video-failed'),
        padding: const EdgeInsets.all(EpSpace.s4),
        decoration: const BoxDecoration(
          color: EpColors.n100,
          borderRadius: EpRadius.mdAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.videocam_off_outlined),
                const SizedBox(width: EpSpace.s2),
                Expanded(
                  child: Text(
                    l10n.videoFailedTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: EpSpace.s2),
            Text(l10n.videoFailedBody),
            const SizedBox(height: EpSpace.s3),
            OutlinedButton(
              onPressed: () => setState(() => _state = _VideoState.idle),
              child: Text(l10n.retryAction),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: EpColors.n900,
          borderRadius: EpRadius.mdAll,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: blockedByWifiSetting ? null : _play,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      size: 64,
                      color: blockedByWifiSetting ? EpColors.n500 : EpColors.n0,
                    ),
                  ),
                  Positioned(
                    left: EpSpace.s3,
                    bottom: EpSpace.s3,
                    child: Text(
                      '${widget.video.durationLabel} · '
                      '${widget.video.sizeMb.toStringAsFixed(1)} MB',
                      style: const TextStyle(
                        color: EpColors.n0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: EpSpace.s2),
        if (blockedByWifiSetting)
          EpBanner(icon: Icons.wifi_rounded, message: l10n.videoWifiOnlyNote)
        else
          Text(
            l10n.videoDataNote(size),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
