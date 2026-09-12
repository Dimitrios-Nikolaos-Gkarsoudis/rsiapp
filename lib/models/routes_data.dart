import 'package:latlong2/latlong.dart';

class RoutesData {
  static final Map<String, List<LatLng>> routes = {
    // --- CHORA (PORT) ---
    "Chora-AgiosProkopios": [LatLng(37.1004, 25.3775), LatLng(37.0850, 25.3650), LatLng(37.0750, 25.3550)],
    "Chora-Plaka": [LatLng(37.1004, 25.3775), LatLng(37.0750, 25.3550), LatLng(37.0500, 25.3650), LatLng(37.0350, 25.3750)],
    "Chora-Halki": [LatLng(37.1004, 25.3775), LatLng(37.0850, 25.4050), LatLng(37.0650, 25.4500)],
    "Chora-Filoti": [LatLng(37.1004, 25.3775), LatLng(37.0850, 25.4050), LatLng(37.0650, 25.4500), LatLng(37.0520, 25.4965)],
    "Chora-Apiranthos": [LatLng(37.1004, 25.3775), LatLng(37.0850, 25.4050), LatLng(37.0650, 25.4500), LatLng(37.0520, 25.4965), LatLng(37.0600, 25.5100), LatLng(37.0720, 25.5200)],
    "Chora-Moutsouna": [LatLng(37.1004, 25.3775), LatLng(37.0850, 25.4050), LatLng(37.0650, 25.4500), LatLng(37.0520, 25.4965), LatLng(37.0600, 25.5100), LatLng(37.0720, 25.5200), LatLng(37.0750, 25.5500), LatLng(37.0780, 25.5840)],
    "Chora-Koronos": [LatLng(37.1004, 25.3775), LatLng(37.0850, 25.4050), LatLng(37.0650, 25.4500), LatLng(37.0520, 25.4965), LatLng(37.0600, 25.5100), LatLng(37.0720, 25.5200), LatLng(37.0900, 25.5250), LatLng(37.1140, 25.5320)],
    "Chora-Apollonas": [LatLng(37.1004, 25.3775), LatLng(37.1200, 25.4200), LatLng(37.1600, 25.5000), LatLng(37.1850, 25.5500)],

    // --- AGIOS PROKOPIOS ---
    "AgiosProkopios-Chora": [LatLng(37.0750, 25.3550), LatLng(37.0850, 25.3650), LatLng(37.1004, 25.3775)],
    "AgiosProkopios-Plaka": [LatLng(37.0750, 25.3550), LatLng(37.0500, 25.3650), LatLng(37.0350, 25.3750)],
    "AgiosProkopios-Halki": [LatLng(37.0750, 25.3550), LatLng(37.0850, 25.3650), LatLng(37.1004, 25.3775), LatLng(37.0850, 25.4050), LatLng(37.0650, 25.4500)],
    "AgiosProkopios-Filoti": [LatLng(37.0750, 25.3550), LatLng(37.0850, 25.4050), LatLng(37.0650, 25.4500), LatLng(37.0520, 25.4965)],
    "AgiosProkopios-Apiranthos": [LatLng(37.0750, 25.3550), LatLng(37.0850, 25.4050), LatLng(37.0650, 25.4500), LatLng(37.0520, 25.4965), LatLng(37.0600, 25.5100), LatLng(37.0720, 25.5200)],
    "AgiosProkopios-Moutsouna": [LatLng(37.0750, 25.3550), LatLng(37.0850, 25.4050), LatLng(37.0650, 25.4500), LatLng(37.0520, 25.4965), LatLng(37.0750, 25.5500), LatLng(37.0780, 25.5840)],
    "AgiosProkopios-Koronos": [LatLng(37.0750, 25.3550), LatLng(37.0850, 25.4050), LatLng(37.0650, 25.4500), LatLng(37.0520, 25.4965), LatLng(37.1140, 25.5320)],
    "AgiosProkopios-Apollonas": [LatLng(37.0750, 25.3550), LatLng(37.0850, 25.4050), LatLng(37.0650, 25.4500), LatLng(37.1850, 25.5500)],

    // --- PLAKA ---
    "Plaka-Chora": [LatLng(37.0350, 25.3750), LatLng(37.0500, 25.3650), LatLng(37.0750, 25.3550), LatLng(37.1004, 25.3775)],
    "Plaka-AgiosProkopios": [LatLng(37.0350, 25.3750), LatLng(37.0500, 25.3650), LatLng(37.0750, 25.3550)],
    "Plaka-Halki": [LatLng(37.0350, 25.3750), LatLng(37.0600, 25.3800), LatLng(37.0650, 25.4500)],
    "Plaka-Filoti": [LatLng(37.0350, 25.3750), LatLng(37.0600, 25.3800), LatLng(37.0850, 25.4050), LatLng(37.0650, 25.4500), LatLng(37.0520, 25.4965)],
    "Plaka-Apiranthos": [LatLng(37.0350, 25.3750), LatLng(37.0600, 25.3800), LatLng(37.0850, 25.4050), LatLng(37.0650, 25.4500), LatLng(37.0520, 25.4965), LatLng(37.0720, 25.5200)],
    "Plaka-Moutsouna": [LatLng(37.0350, 25.3750), LatLng(37.0600, 25.3800), LatLng(37.0850, 25.4050), LatLng(37.0780, 25.5840)],
    "Plaka-Koronos": [LatLng(37.0350, 25.3750), LatLng(37.1140, 25.5320)],
    "Plaka-Apollonas": [LatLng(37.0350, 25.3750), LatLng(37.1850, 25.5500)],

    // --- HALKI ---
    "Halki-Chora": [LatLng(37.0650, 25.4500), LatLng(37.0850, 25.4050), LatLng(37.1004, 25.3775)],
    "Halki-AgiosProkopios": [LatLng(37.0650, 25.4500), LatLng(37.0750, 25.3550)],
    "Halki-Plaka": [LatLng(37.0650, 25.4500), LatLng(37.0350, 25.3750)],
    "Halki-Filoti": [LatLng(37.0650, 25.4500), LatLng(37.0520, 25.4965)],
    "Halki-Apiranthos": [LatLng(37.0650, 25.4500), LatLng(37.0520, 25.4965), LatLng(37.0720, 25.5200)],
    "Halki-Moutsouna": [LatLng(37.0650, 25.4500), LatLng(37.0520, 25.4965), LatLng(37.0780, 25.5840)],
    "Halki-Koronos": [LatLng(37.0650, 25.4500), LatLng(37.1140, 25.5320)],
    "Halki-Apollonas": [LatLng(37.0650, 25.4500), LatLng(37.1850, 25.5500)],

    // --- FILOTI ---
    "Filoti-Chora": [LatLng(37.0520, 25.4965), LatLng(37.0650, 25.4500), LatLng(37.0850, 25.4050), LatLng(37.1004, 25.3775)],
    "Filoti-AgiosProkopios": [LatLng(37.0520, 25.4965), LatLng(37.0750, 25.3550)],
    "Filoti-Plaka": [LatLng(37.0520, 25.4965), LatLng(37.0350, 25.3750)],
    "Filoti-Halki": [LatLng(37.0520, 25.4965), LatLng(37.0650, 25.4500)],
    "Filoti-Apiranthos": [LatLng(37.0520, 25.4965), LatLng(37.0600, 25.5100), LatLng(37.0720, 25.5200)],
    "Filoti-Moutsouna": [LatLng(37.0520, 25.4965), LatLng(37.0780, 25.5840)],
    "Filoti-Koronos": [LatLng(37.0520, 25.4965), LatLng(37.1140, 25.5320)],
    "Filoti-Apollonas": [LatLng(37.0520, 25.4965), LatLng(37.1850, 25.5500)],

    // --- APIRANTHOS ---
    "Apiranthos-Chora": [LatLng(37.0720, 25.5200), LatLng(37.0520, 25.4965), LatLng(37.1004, 25.3775)],
    "Apiranthos-AgiosProkopios": [LatLng(37.0720, 25.5200), LatLng(37.0750, 25.3550)],
    "Apiranthos-Plaka": [LatLng(37.0720, 25.5200), LatLng(37.0350, 25.3750)],
    "Apiranthos-Halki": [LatLng(37.0720, 25.5200), LatLng(37.0650, 25.4500)],
    "Apiranthos-Filoti": [LatLng(37.0720, 25.5200), LatLng(37.0600, 25.5100), LatLng(37.0520, 25.4965)],
    "Apiranthos-Moutsouna": [LatLng(37.0720, 25.5200), LatLng(37.0780, 25.5840)],
    "Apiranthos-Koronos": [LatLng(37.0720, 25.5200), LatLng(37.1140, 25.5320)],
    "Apiranthos-Apollonas": [LatLng(37.0720, 25.5200), LatLng(37.1850, 25.5500)],

    // --- MOUTSOUNA ---
    "Moutsouna-Chora": [LatLng(37.0780, 25.5840), LatLng(37.1004, 25.3775)],
    "Moutsouna-AgiosProkopios": [LatLng(37.0780, 25.5840), LatLng(37.0750, 25.3550)],
    "Moutsouna-Plaka": [LatLng(37.0780, 25.5840), LatLng(37.0350, 25.3750)],
    "Moutsouna-Halki": [LatLng(37.0780, 25.5840), LatLng(37.0650, 25.4500)],
    "Moutsouna-Filoti": [LatLng(37.0780, 25.5840), LatLng(37.0520, 25.4965)],
    "Moutsouna-Apiranthos": [LatLng(37.0780, 25.5840), LatLng(37.0720, 25.5200)],
    "Moutsouna-Koronos": [LatLng(37.0780, 25.5840), LatLng(37.1140, 25.5320)],
    "Moutsouna-Apollonas": [LatLng(37.0780, 25.5840), LatLng(37.1850, 25.5500)],

    // --- KORONOS ---
    "Koronos-Chora": [LatLng(37.1140, 25.5320), LatLng(37.1004, 25.3775)],
    "Koronos-AgiosProkopios": [LatLng(37.1140, 25.5320), LatLng(37.0750, 25.3550)],
    "Koronos-Plaka": [LatLng(37.1140, 25.5320), LatLng(37.0350, 25.3750)],
    "Koronos-Halki": [LatLng(37.1140, 25.5320), LatLng(37.0650, 25.4500)],
    "Koronos-Filoti": [LatLng(37.1140, 25.5320), LatLng(37.0520, 25.4965)],
    "Koronos-Apiranthos": [LatLng(37.1140, 25.5320), LatLng(37.0720, 25.5200)],
    "Koronos-Moutsouna": [LatLng(37.1140, 25.5320), LatLng(37.0780, 25.5840)],
    "Koronos-Apollonas": [LatLng(37.1140, 25.5320), LatLng(37.1850, 25.5500)],

    // --- APOLLONAS ---
    "Apollonas-Chora": [LatLng(37.1850, 25.5500), LatLng(37.1004, 25.3775)],
    "Apollonas-AgiosProkopios": [LatLng(37.1850, 25.5500), LatLng(37.0750, 25.3550)],
    "Apollonas-Plaka": [LatLng(37.1850, 25.5500), LatLng(37.0350, 25.3750)],
    "Apollonas-Halki": [LatLng(37.1850, 25.5500), LatLng(37.0650, 25.4500)],
    "Apollonas-Filoti": [LatLng(37.1850, 25.5500), LatLng(37.0520, 25.4965)],
    "Apollonas-Apiranthos": [LatLng(37.1850, 25.5500), LatLng(37.0720, 25.5200)],
    "Apollonas-Moutsouna": [LatLng(37.1850, 25.5500), LatLng(37.0780, 25.5840)],
    "Apollonas-Koronos": [LatLng(37.1850, 25.5500), LatLng(37.1140, 25.5320)]
  };

  static final Map<String, String> names = {
    "Chora": "Χώρα (Λιμάνι)",
    "AgiosProkopios": "Άγιος Προκόπιος",
    "Plaka": "Πλάκα",
    "Halki": "Χαλκί",
    "Filoti": "Φιλώτι",
    "Apiranthos": "Απείρανθος",
    "Moutsouna": "Μουτσούνα",
    "Koronos": "Κόρωνος",
    "Apollonas": "Απόλλωνας",
  };
}