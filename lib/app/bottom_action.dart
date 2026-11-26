import 'package:flutter/material.dart';

/// Page body with scrolling [content] and the page's main [action] pinned
/// below it (T36).
///
/// Lives in [Scaffold.body] rather than [Scaffold.bottomNavigationBar]: only
/// the body is resized for the on-screen keyboard, so the action rises above
/// it. On iOS a multi-line field has no key that closes the keyboard, so an
/// action under it could not be reached at all.
class BodyWithBottomAction extends StatelessWidget {
  const BodyWithBottomAction({
    super.key,
    required this.content,
    required this.action,
  });

  final Widget content;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: content),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: action,
          ),
        ),
      ],
    );
  }
}
