import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/sites/site_suggestions.dart';
import '../../l10n/app_localizations.dart';

/// „Tauchplatz“ with suggestions below it while it has the focus
/// (ui-spec §5.4, ADR 0006). The list sits in the page, not in an overlay,
/// so it scrolls with the form and reads in order with a screen reader.
class SiteField extends ConsumerStatefulWidget {
  const SiteField({
    super.key,
    required this.controller,
    required this.onChosen,
    required this.onTyped,
  });

  final TextEditingController controller;

  /// A suggestion was tapped; the field already shows its name.
  final ValueChanged<SiteSuggestion> onChosen;

  /// The user typed; any earlier choice no longer applies.
  final ValueChanged<String> onTyped;

  @override
  ConsumerState<SiteField> createState() => _SiteFieldState();
}

class _SiteFieldState extends ConsumerState<SiteField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _choose(SiteSuggestion s) {
    widget.controller.value = TextEditingValue(
      text: s.name,
      selection: TextSelection.collapsed(offset: s.name.length),
    );
    _focus.unfocus();
    widget.onChosen(s);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final suggester = ref.watch(siteSuggesterProvider).value;
    final own = ref.watch(ownSitesProvider).value ?? const [];
    final visited = ref.watch(visitedCountriesProvider).value ?? const {};

    final suggestions = !_focus.hasFocus || suggester == null
        ? const <SiteSuggestion>[]
        : suggester.suggest(
            widget.controller.text,
            own: own,
            visitedCountries: visited,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          maxLength: maxSiteNameLength,
          buildCounter: (
            _, {
            required currentLength,
            required isFocused,
            maxLength,
          }) => null,
          onChanged: (text) {
            widget.onTyped(text);
            setState(() {});
          },
          decoration: InputDecoration(labelText: l10n.fieldSite),
        ),
        if (suggestions.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 4),
            child: Column(
              children: [
                for (final s in suggestions)
                  switch (s) {
                    OwnSiteSuggestion() => ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(s.name),
                      onTap: () => _choose(s),
                    ),
                    CatalogueSiteSuggestion(:final place) => ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(s.name),
                      subtitle: place == null ? null : Text(place),
                      onTap: () => _choose(s),
                    ),
                    NewSiteSuggestion() => ListTile(
                      leading: const Icon(Icons.add_location_alt_outlined),
                      title: Text(l10n.siteUseNew(s.name)),
                      onTap: () => _choose(s),
                    ),
                  },
              ],
            ),
          ),
      ],
    );
  }
}
