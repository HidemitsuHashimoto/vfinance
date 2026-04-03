import 'package:flutter_test/flutter_test.dart';
import 'package:vfinance/domain/year_backup_file_name.dart';

void main() {
  test('buildYearBackupFileName follows gastos_YYYY.json', () {
    expect(buildYearBackupFileName(2024), 'gastos_2024.json');
    expect(buildYearBackupFileName(2026), 'gastos_2026.json');
  });

  test('tryParseYearFromBackupFileName accepts basename pattern only', () {
    expect(tryParseYearFromBackupFileName('gastos_2025.json'), 2025);
    expect(tryParseYearFromBackupFileName('/path/gastos_2025.json'), isNull);
    expect(tryParseYearFromBackupFileName('other.json'), isNull);
  });
}
