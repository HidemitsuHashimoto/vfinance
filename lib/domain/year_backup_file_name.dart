/// Default backup filename pattern from [domain.md]: `gastos_YYYY.json`.
String buildYearBackupFileName(int year) {
  return 'gastos_$year.json';
}

final RegExp _kBackupBasenamePattern = RegExp(r'^gastos_(\d{4})\.json$');

/// Returns the year if [fileName] is exactly `gastos_YYYY.json` (no path).
int? tryParseYearFromBackupFileName(String fileName) {
  final RegExpMatch? m = _kBackupBasenamePattern.firstMatch(fileName);
  if (m == null) {
    return null;
  }
  return int.tryParse(m.group(1)!);
}
