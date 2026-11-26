import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/bottom_action.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/feedback/feedback_mail.dart';
import '../../l10n/app_localizations.dart';
import 'diagnostics_screen.dart';

/// „Fehler melden“ / „Verbesserung vorschlagen“ (ui-spec §5.14, T35): the
/// app prepares a mail draft; the user sends it from the mail app.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key, required this.kind});

  static const bugPath = '/feedback/bug';
  static const ideaPath = '/feedback/idea';

  final FeedbackKind kind;

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  bool _attachLog = true;
  bool _submitted = false;
  bool _busy = false;

  /// Whether there is a log to attach; null while it is read.
  late final Future<bool> _hasLog = widget.kind == FeedbackKind.bug
      ? ref.read(diagnosticLogProvider).lines().then((l) => l.isNotEmpty)
      : Future.value(false);

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _isBug => widget.kind == FeedbackKind.bug;

  Future<void> _prepare() async {
    setState(() => _submitted = true);
    if (_text.text.trim().isEmpty) {
      _focus.requestFocus();
      return;
    }
    setState(() => _busy = true);
    try {
      final header = await ref.read(diagnosticHeaderProvider.future);
      ({String name, Uint8List bytes})? attachment;
      if (_isBug && _attachLog && await _hasLog) {
        final text = await ref.read(diagnosticLogProvider).export(header);
        final day = DateFormat('yyyy-MM-dd').format(clock.now());
        attachment = (
          name: 'DiveDown-Diagnose-$day.txt',
          bytes: utf8.encode(text),
        );
      }
      final mail = buildFeedbackMail(
        widget.kind,
        _text.text,
        header,
        attachment: attachment,
      );
      final result = await ref.read(feedbackMailerProvider).compose(mail);
      if (result == MailResult.noMailApp && mounted) await _noMailApp();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _noMailApp() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.feedbackNoMailTitle),
        content: Text(l10n.feedbackNoMailBody(feedbackAddress)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.feedbackClose),
          ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(
                const ClipboardData(text: feedbackAddress),
              );
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.feedbackAddressCopied)),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.feedbackCopyAddress),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.extension<DiveColors>()!.onSurfaceMuted;
    final missing = _submitted && _text.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isBug ? l10n.feedbackBugEntry : l10n.feedbackIdeaEntry),
      ),
      body: BodyWithBottomAction(
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.feedbackPrepareNote(feedbackAddress),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: _busy ? null : _prepare,
              icon: const Icon(Icons.mail_outline),
              label: Text(l10n.feedbackPrepare),
            ),
          ],
        ),
        content: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            TextField(
              controller: _text,
              focusNode: _focus,
              minLines: 5,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.requiredField(
                  _isBug ? l10n.feedbackBugField : l10n.feedbackIdeaField,
                ),
                hintText: _isBug ? l10n.feedbackBugHint : l10n.feedbackIdeaHint,
                hintMaxLines: 3,
                alignLabelWithHint: true,
                errorText: !missing
                    ? null
                    : _isBug
                    ? l10n.feedbackBugMissing
                    : l10n.feedbackIdeaMissing,
              ),
            ),
            if (_isBug)
              FutureBuilder<bool>(
                future: _hasLog,
                builder: (context, snapshot) {
                  if (snapshot.data != true) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.feedbackAttachLog),
                          subtitle: Text(l10n.feedbackAttachLogHint),
                          value: _attachLog,
                          onChanged: (v) => setState(() => _attachLog = v),
                        ),
                        TextButton.icon(
                          onPressed: () => context.push(DiagnosticsScreen.path),
                          icon: const Icon(Icons.visibility_outlined),
                          label: Text(l10n.feedbackViewLog),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
