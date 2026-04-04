import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/year_backup_codec.dart';
import 'package:vfinance/domain/year_backup_file_name.dart';
import 'package:vfinance/domain/year_backup_snapshot.dart';
import 'package:vfinance/l10n/app_localizations.dart';

/// Export/import per-year JSON via storage picker ([domain.md]).
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  int _year = DateTime.now().year;
  bool _busy = false;

  List<int> get _yearChoices {
    final int y = DateTime.now().year;
    return List<int>.generate(12, (int i) => y - i);
  }

  Future<void> _export(BuildContext context) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    setState(() => _busy = true);
    try {
      final YearBackupSnapshot snapshot = await repo
          .buildYearBackupForCalendarYear(_year);
      final String json = encodeYearBackupSnapshot(snapshot);
      final Uint8List bytes = Uint8List.fromList(utf8.encode(json));
      await FilePicker.platform.saveFile(
        dialogTitle: l.backupSaveDialogTitle,
        fileName: buildYearBackupFileName(_year),
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: <String>['json'],
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.backupGenerated)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.backupExportFailed('$e'))));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _import(BuildContext context) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    final PlatformFile file = result.files.single;
    if (file.bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.backupReadFailed)));
      }
      return;
    }
    final String text = utf8.decode(file.bytes!);
    late final YearBackupSnapshot snapshot;
    try {
      snapshot = decodeYearBackupSnapshot(text);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.backupInvalidJson('$e'))));
      }
      return;
    }
    if (!context.mounted) {
      return;
    }
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(l.restoreDialogTitle),
          content: Text(l.restoreDialogBody(snapshot.year)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.restoreAction),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await repo.importYearBackupSnapshot(snapshot);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.restoreDone(snapshot.year))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.restoreFailed('$e'))));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _confirmClearAllDebug(BuildContext context) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(l.backupDebugClearConfirmTitle),
          content: Text(l.backupDebugClearConfirmBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.onError,
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: Text(l.deleteAction),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) {
      return;
    }
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    setState(() => _busy = true);
    try {
      await repo.clearAllLocalData();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.backupDebugClearDone)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.backupDebugClearFailed('$e'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(l.backupSectionTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            l.backupDescription(buildYearBackupFileName(_year)),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<int>(
            initialValue: _year,
            decoration: InputDecoration(labelText: l.backupYearLabel),
            items: _yearChoices
                .map(
                  (int y) => DropdownMenuItem<int>(value: y, child: Text('$y')),
                )
                .toList(),
            onChanged: _busy
                ? null
                : (int? y) {
                    if (y != null) {
                      setState(() => _year = y);
                    }
                  },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : () => _export(context),
            icon: const Icon(Icons.upload_file),
            label: Text(l.commonExport),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _import(context),
            icon: const Icon(Icons.download_outlined),
            label: Text(l.commonImport),
          ),
          if (kDebugMode) ...<Widget>[
            const SizedBox(height: 32),
            Text(
              l.backupDebugClearSectionTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l.backupDebugClearDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _confirmClearAllDebug(context),
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(l.backupDebugClearButton),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
          if (_busy) ...<Widget>[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
