import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bottom_action.dart';
import '../../app/providers.dart';
import '../../data/diagnostics/log_sanitizer.dart' show appLogCategory;
import '../../data/platform/share_photo.dart';
import '../../domain/diagnostics/diagnostic_log.dart';
import '../../domain/dive/dive.dart';
import '../../domain/share/share_card.dart';
import '../../l10n/app_localizations.dart';
import 'share_card_painter.dart';

/// „Tauchgang teilen“ (ui-spec §5.16, T43): a photo from the gallery with
/// the dive's card on it, handed to the system share dialog as a PNG.
class ShareDiveScreen extends ConsumerStatefulWidget {
  const ShareDiveScreen({super.key, required this.diveId});

  static String pathFor(String diveId) => '/logbook/dive/$diveId/share';

  final String diveId;

  @override
  ConsumerState<ShareDiveScreen> createState() => _ShareDiveScreenState();
}

class _ShareDiveScreenState extends ConsumerState<ShareDiveScreen> {
  ShareCardLayout _layout = const ShareCardLayout();
  ui.Image? _photo;
  bool _busy = false;
  double _pinchBase = 1;

  @override
  void initState() {
    super.initState();
    ref.read(appSettingsProvider).shareCardLayout().then((stored) {
      if (stored != null && mounted) setState(() => _layout = stored);
    });
  }

  @override
  void dispose() {
    _photo?.dispose();
    super.dispose();
  }

  void _change(ShareCardLayout layout, {bool save = false}) {
    setState(() => _layout = layout);
    if (save) _save();
  }

  void _save() => ref.read(appSettingsProvider).setShareCardLayout(_layout);

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(sharePhotoLoaderProvider)();
    if (!mounted) {
      if (result is SharePhoto) result.image.dispose();
      return;
    }
    switch (result) {
      case null:
        return;
      case SharePhotoFailed():
        messenger.showSnackBar(SnackBar(content: Text(l10n.sharePhotoFailed)));
      case SharePhoto(:final image):
        final old = _photo;
        setState(() => _photo = image);
        old?.dispose();
    }
  }

  void _removePhoto() {
    final old = _photo;
    setState(() => _photo = null);
    old?.dispose();
  }

  Future<void> _share(Dive dive) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final log = ref.read(diagnosticLogProvider);
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(shareImageRendererProvider)(
        content: shareCardContent(dive),
        layout: _layout,
        l10n: l10n,
        photo: _photo,
      );
      await log.log(appLogCategory, LogLevel.info, 'share image created');
      await ref.read(shareFileProvider)(shareImageName(dive), bytes);
    } on Object catch (e) {
      await log.log(
        appLogCategory,
        LogLevel.error,
        'share failed: ${e.runtimeType}',
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dive = ref.watch(diveDetailProvider(widget.diveId)).value?.dive;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shareTitle)),
      body: dive == null
          ? const SizedBox.shrink()
          : BodyWithBottomAction(
              content: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Center(child: _preview(l10n, dive)),
                    ),
                  ),
                  _controls(l10n),
                ],
              ),
              action: SizedBox(
                height: 56,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _share(dive),
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share_outlined),
                  label: Text(l10n.shareAction),
                ),
              ),
            ),
    );
  }

  Widget _preview(AppLocalizations l10n, Dive dive) {
    final content = shareCardContent(dive);
    return AspectRatio(
      key: const ValueKey('share-preview'),
      aspectRatio: shareImageWidth / shareImageHeight,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          final card = ShareCardPainter.cardRect(size, _layout);
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Semantics(
                    image: true,
                    label: _photo == null
                        ? l10n.sharePreviewPlain
                        : l10n.sharePreviewPhoto,
                    child: CustomPaint(
                      painter: ShareCardPainter(
                        content: content,
                        layout: _layout,
                        l10n: l10n,
                        photo: _photo,
                      ),
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: card,
                  child: Semantics(
                    key: const ValueKey('share-card'),
                    container: true,
                    label: l10n.shareCardSemantics(
                      _positionWord(l10n),
                      (_layout.scale * 100).round(),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: (_) => _pinchBase = _layout.scale,
                      onScaleUpdate: (d) {
                        var next = ShareCardPainter.dragged(
                          _layout,
                          size,
                          d.focalPointDelta,
                        );
                        if (d.pointerCount > 1) {
                          next = next.copyWith(scale: _pinchBase * d.scale);
                        }
                        _change(next);
                      },
                      onScaleEnd: (_) => _save(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _positionWord(AppLocalizations l10n) =>
      (_layout.y < 1 / 3
              ? l10n.sharePositionTop
              : _layout.y < 2 / 3
              ? l10n.sharePositionMiddle
              : l10n.sharePositionBottom)
          .toLowerCase();

  Widget _controls(AppLocalizations l10n) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium;
    Widget row(String label, Widget child) => Row(
      children: [
        SizedBox(width: 88, child: Text(label, style: labelStyle)),
        Expanded(child: child),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickPhoto,
                icon: const Icon(Icons.photo_outlined),
                label: Text(l10n.sharePickPhoto),
              ),
              if (_photo != null)
                TextButton(
                  onPressed: _busy ? null : _removePhoto,
                  child: Text(l10n.shareRemovePhoto),
                ),
            ],
          ),
          row(
            l10n.shareSize,
            Slider(
              key: const ValueKey('share-size'),
              value: _layout.scale,
              min: ShareCardLayout.minScale,
              max: ShareCardLayout.maxScale,
              divisions: 10,
              semanticFormatterCallback: (v) =>
                  l10n.shareSizeValue((v * 100).round()),
              onChanged: (v) => _change(_layout.copyWith(scale: v)),
              onChangeEnd: (_) => _save(),
            ),
          ),
          row(
            l10n.shareOpacity,
            Slider(
              key: const ValueKey('share-opacity'),
              value: _layout.opacity,
              divisions: 20,
              semanticFormatterCallback: (v) =>
                  l10n.shareOpacityValue((v * 100).round()),
              onChanged: (v) => _change(_layout.copyWith(opacity: v)),
              onChangeEnd: (_) => _save(),
            ),
          ),
          row(
            l10n.sharePosition,
            Wrap(
              spacing: 8,
              children: [
                for (final (anchor, label) in [
                  (ShareCardAnchor.top, l10n.sharePositionTop),
                  (ShareCardAnchor.middle, l10n.sharePositionMiddle),
                  (ShareCardAnchor.bottom, l10n.sharePositionBottom),
                ])
                  OutlinedButton(
                    onPressed: () =>
                        _change(_layout.anchoredAt(anchor), save: true),
                    child: Text(label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `DiveDown-2026-11-14-42.png` (ui-spec §5.16).
String shareImageName(Dive dive) {
  String two(int v) => v.toString().padLeft(2, '0');
  final s = dive.start;
  final date = '${s.year}-${two(s.month)}-${two(s.day)}';
  return dive.number == null
      ? 'DiveDown-$date.png'
      : 'DiveDown-$date-${dive.number}.png';
}
