import 'package:flutter/foundation.dart';

/// Package name of the catalogue entry on the licence page.
const catalogueLicenceName = 'Tauchplatz-Katalog';

bool _registered = false;

/// Adds the ODbL notice of the bundled site catalogue to the licence page
/// (ADR 0006, ui-spec §5.11). Call once at start.
void registerCatalogueLicence() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(
    () => Stream.value(
      const LicenseEntryWithLineBreaks([catalogueLicenceName], _notice),
    ),
  );
}

const _notice = '''
Enthält Daten von OpenStreetMap, verfügbar unter der Open Database License (ODbL) 1.0. © OpenStreetMap-Mitwirkende, https://www.openstreetmap.org/copyright

Der Tauchplatz-Katalog von DiveDown ist ein gefilterter Auszug aus dem Katalog von Submersion (https://github.com/submersion-app/submersion) und steht unter der Open Database License (ODbL) 1.0, https://opendatacommons.org/licenses/odbl/1-0/ . Er enthält nur Einträge aus OpenStreetMap (ODbL 1.0), Wikidata (CC0 1.0, https://www.wikidata.org/wiki/Wikidata:Copyright) und von Submersion kuratierte Einträge (ODbL 1.0).

Der gefilterte Datensatz liegt öffentlich im Quellcode von DiveDown unter assets/data/dive_sites.json.gz.''';
