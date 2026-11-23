import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import 'dive_detail_screen.dart';
import 'manual_dive_screen.dart';
import 'profile_chart.dart';

/// The profile alone, in landscape without system bars, with zoom
/// (ui-spec §6, §8, T27). Orientation and bars come back on close.
class ProfileFullscreenScreen extends ConsumerStatefulWidget {
  const ProfileFullscreenScreen({super.key, required this.diveId});

  static String pathFor(String diveId) =>
      '${DiveDetailScreen.pathFor(diveId)}/profile';

  final String diveId;

  @override
  ConsumerState<ProfileFullscreenScreen> createState() =>
      _ProfileFullscreenScreenState();
}

class _ProfileFullscreenScreenState
    extends ConsumerState<ProfileFullscreenScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const []);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(diveDetailProvider(widget.diveId)).value;
    final dive = detail?.dive;
    return Scaffold(
      key: const ValueKey('profile-fullscreen'),
      body: SafeArea(
        child: dive == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: l10n.profileFullscreenClose,
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              if (dive.number case final n?) l10n.diveNumber(n),
                              ?dive.siteName,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ProfileChart(
                        dive: dive,
                        fullscreen: true,
                        // The form is not made for landscape: close first.
                        onEdit: () {
                          final router = GoRouter.of(context);
                          router.pop();
                          router.push(ManualDiveScreen.editPathFor(dive.id!));
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
