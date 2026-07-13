# Löschwasserförderung

**Applikation zur automatischen Berechnung von Relaisleitungen und Pumpenstandorten für Feuerwehreinsätze**

[![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter)](https://flutter.dev)
[![Plattformen](https://img.shields.io/badge/Plattformen-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-informational)](#unterstützte-plattformen)
[![Lizenz: AGPL v3](https://img.shields.io/badge/Lizenz-AGPL%20v3-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.33.63-green.svg)](pubspec.yaml)

> Diplomarbeit von **Stefan Rautner** · HTBLA Saalfelden · Schuljahr 2024/25
> In Kooperation mit [Team122.at](https://www.team122.at) und der Freiwilligen Feuerwehr Kuchl
> Live: [löschwasserförderung.at](https://xn--lschwasserfrderung-d3bk.at)

---

## Überblick

Der Aufbau einer **Relaisleitung** – einer langen Schlauchleitung mit zwischengeschalteten
Verstärkerpumpen zur Förderung von Löschwasser über größere Distanzen und Höhenunterschiede –
ist im Feuerwehreinsatz zeitkritisch und fehleranfällig. Die manuelle Planung der
Pumpenstandorte kostet wertvolle Zeit.

**Löschwasserförderung** löst dieses Problem: Die App berechnet auf Basis von Kartendaten,
Höhenprofilen und Routenoptimierung **automatisch die optimalen Pumpenstandorte** entlang
einer gewählten Strecke – unter Berücksichtigung von Reibungsverlust, Höhenmetern und
Druckreserven. Das Ergebnis ist eine schnellere, präzisere und sicherere Einsatzplanung.

> *„Moderne Technologie trifft Feuerwehrpraxis – präzise, schnell, lebensrettend.“*

---

## Funktionen

- 🗺️ **Interaktive Karte** auf OpenStreetMap-Basis (Vektor-/Rasterkacheln)
- 📍 **Automatische Berechnung von Pumpenstandorten** entlang einer Relaisleitung
- ⛰️ **Höhenprofil-Auswertung** – Höhenmeter fließen in die Druck- und Pumpenberechnung ein
- 🚒 **Wasserentnahmestellen** – Hydranten, Löschwasserbehälter, -brunnen, -teiche und Saugstellen werden angezeigt
- 🔄 **GPS-Tracking** in Echtzeit inkl. Hintergrunddienst und Benachrichtigungen
- 🔍 **Adress- und Hofnamensuche** mit Autovervollständigung
- 🧭 **Fußgänger-Routing** über OSRM zur Streckenermittlung
- ⚙️ **Konfigurierbare Parameter** (max. Druckverlust, Reibungsverlust, Reserve-Schlauchlänge)
- 👥 **Benutzerverwaltung & Support-System** mit Login, E-Mail-Support und Admin-Dashboard
- 🎥 Integrierter Trailer und Impressum

---

## Technologie-Stack

| Bereich          | Technologie                                              |
|------------------|----------------------------------------------------------|
| Frontend         | Flutter / Dart (`^3.10.7`)                               |
| Karte            | `flutter_map`, `latlong2`, OpenStreetMap                 |
| Standort         | `geolocator`, `flutter_map_location_marker`             |
| Backend          | PHP + MySQL (REST-Endpunkte im Ordner `api/`)           |
| Speicherung      | `shared_preferences`, `flutter_secure_storage`          |
| Kommunikation    | `http`, `dio`                                            |
| Verschlüsselung  | `encrypt` (AES) + `.env`-basierte Schlüssel             |
| Benachrichtigung | `awesome_notifications`, `flutter_background_service`   |
| Medien           | `media_kit`, `audioplayers`                             |

### Externe Datenquellen & APIs

| Zweck                       | Quelle                                                          |
|-----------------------------|----------------------------------------------------------------|
| Kartenmaterial              | [OpenStreetMap](https://www.openstreetmap.org)                 |
| Berechnung Relaisleitung / Höhe | [elevation.geocode.at](https://elevation.geocode.at)      |
| Routenberechnung (OSRM)     | [routing.openstreetmap.de](https://routing.openstreetmap.de)   |
| Wasserentnahmestellen       | [Overpass API](https://www.overpass-api.de) / objektdatenbank.at |
| Adress- & Hofnamensuche     | [geocode.at](https://www.geocode.at)                           |
| Fehlende Hydranten melden   | [osmhydrant.org](https://www.osmhydrant.org/beta)              |

---

## Unterstützte Plattformen

Android · iOS · Web · Windows · macOS · Linux

---

## Projektstruktur

```
loeschwasserfoerderung.at/
├── lib/                  # Flutter-/Dart-Quellcode
│   ├── main.dart         # Einstiegspunkt, Karte & Relaisleitungs-Logik
│   ├── login.dart        # Authentifizierung
│   ├── location_search_page.dart  # Adress- & Hofnamensuche
│   ├── support_*.dart    # Support-System (Dashboard, Nachrichten, Benutzer)
│   ├── settings.dart     # Einstellungen / Berechnungsparameter
│   ├── impressum.dart    # Impressum, Quellen, Trailer
│   └── ...               # Widgets, Dialoge, Crypto, Marker
├── api/                  # PHP-Backend (Benutzer, E-Mail, Support)
│   └── phpMailer/        # PHPMailer-Bibliothek
├── assets/
│   ├── config/           # .env / .env_web (Verschlüsselungsschlüssel)
│   ├── hydrant_logos/    # Symbole für Wasserentnahmestellen
│   ├── icons/            # App-Icons
│   └── sounds/           # Benachrichtigungston
├── docs/                 # Diplomarbeit: Diagramme, Doku, Präsentationen, Plakat
├── android/ ios/ web/    # Plattform-Projekte
├── windows/ macos/ linux/
└── pubspec.yaml          # Abhängigkeiten & Metadaten
```

Umfangreiche Dokumentation – Klassen-, Sequenz-, Aktivitäts- und Komponentendiagramme,
Anforderungsanalyse sowie die schriftliche Diplomarbeit – befindet sich im Ordner
[`docs/`](docs/).

---

## Einrichtung & Start

### Voraussetzungen

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.10.7`)
- Für das Backend: Webserver mit PHP und MySQL

### Konfiguration

Die App erwartet Konfigurationsdateien mit AES-Schlüsseln unter `assets/config/`.
Trage in `.env` (Mobile/Desktop) und `.env_web` (Web) gültige Werte ein:

```env
ENCRYPTION_KEY=<32-stelliger-Schlüssel>   # 32 Zeichen
ENCRYPTION_IV=<16-stelliger-IV>           # 16 Zeichen
```

Für das PHP-Backend die Platzhalter in `api/db_connection.php`
(`<<HOST>>`, `<<DB>>`, `<<USER>>`, `<<PASSWORD>>`) sowie in
`api/crypto.php` und `api/email_connection.php` mit den realen Zugangsdaten befüllen.

> ⚠️ Schlüssel und Zugangsdaten sind **niemals** ins Repository einzuchecken.

### App bauen & starten

```bash
# Abhängigkeiten installieren
flutter pub get

# App-Icons generieren (optional)
dart run flutter_launcher_icons

# Im Debug-Modus starten
flutter run

# Release-Builds
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web
flutter build windows    # Windows
```

### Backend

Die PHP-Dateien im Ordner `api/` (Benutzerverwaltung, Support-E-Mails, Authentifizierung)
werden auf einem Webserver bereitgestellt und über die in der App hinterlegten
REST-Endpunkte (`https://xn--lschwasserfrderung-d3bk.at/api/...`) angesprochen.

---

## Lizenz

Dieses Projekt steht unter der **GNU Affero General Public License v3.0** – siehe [`LICENSE`](LICENSE).

---

## Credits & Dank

- **Autor:** Stefan Rautner ([Portfolio](https://stefanrautner.github.io/Portfolio/) · [GitHub @StefanRautner](https://github.com/StefanRautner))
- **Betreuer:** Dipl.-Ing. (FH) Markus Falkensteiner, Dipl.-Ing. Raimund Eigner
- **Partner:** [Team122.at](https://www.team122.at), Freiwillige Feuerwehr Kuchl
- **Schule:** HTBLA Saalfelden, Schuljahr 2024/25

Besonderer Dank an alle Betreuer, Partner und Einsatzkräfte, die zur Umsetzung
dieser Diplomarbeit beigetragen haben.

---

*Kontakt: stefan.rautner06@gmail.com*
