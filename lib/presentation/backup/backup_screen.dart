import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/year_backup_codec.dart';
import 'package:vfinance/domain/year_backup_file_name.dart';
import 'package:vfinance/domain/year_backup_snapshot.dart';

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
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    setState(() => _busy = true);
    try {
      final YearBackupSnapshot snapshot = await repo
          .buildYearBackupForCalendarYear(_year);
      final String json = encodeYearBackupSnapshot(snapshot);
      final Uint8List bytes = Uint8List.fromList(utf8.encode(json));
      await FilePicker.platform.saveFile(
        dialogTitle: 'Salvar backup',
        fileName: buildYearBackupFileName(_year),
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: <String>['json'],
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup gerado. Escolha onde salvar.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Falha ao exportar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _import(BuildContext context) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível ler o arquivo.')),
        );
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
        ).showSnackBar(SnackBar(content: Text('JSON inválido: $e')));
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
          title: const Text('Restaurar backup?'),
          content: Text(
            'Os lançamentos e faturas de ${snapshot.year} serão '
            'substituídos pelos dados do arquivo. Outros anos não são '
            'alterados.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restaurar'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dados de ${snapshot.year} restaurados.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Falha ao importar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Backup por ano (JSON)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Exporta ou restaura dados de um ano civil. Nome sugerido: '
            '${buildYearBackupFileName(_year)}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<int>(
            initialValue: _year,
            decoration: const InputDecoration(labelText: 'Ano do backup'),
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
            label: const Text('Exportar…'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _import(context),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Importar arquivo…'),
          ),
          if (_busy) ...<Widget>[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
