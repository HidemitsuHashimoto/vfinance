import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/transaction_enums.dart';
import 'package:vfinance/l10n/app_localizations.dart';
import 'package:vfinance/domain/finance_calendar_date.dart';
import 'package:vfinance/presentation/formatting/amount_format.dart';
import 'package:vfinance/presentation/l10n/transaction_labels.dart';

/// Lists finance transactions (newest first).
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const int _defaultRangeInDays = 30;

  FinanceLocalRepository? _repositoryForStreams;
  Stream<List<FinanceTransaction>>? _transactionsStream;
  final DateFormat _dayFormat = DateFormat('dd/MM/yyyy');
  DateTime? _currentDate;
  DateTime? _periodStartDate;
  DateTime? _periodEndDate;
  late DateFormat _currentDateFormat;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    _currentDateFormat = DateFormat('d \'de\' MMMM', 'pt_BR');
    if (_repositoryForStreams != repo) {
      _repositoryForStreams = repo;
      final DateTime today = _normalizeDate(DateTime.now());
      _currentDate = today;
      _periodEndDate = today;
      _periodStartDate = _normalizeDate(
        today.subtract(const Duration(days: _defaultRangeInDays)),
      );
      _refreshTransactionsStream();
    }
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _mustCurrentDate() => _currentDate!;
  DateTime _mustStartDate() => _periodStartDate!;
  DateTime _mustEndDate() => _periodEndDate!;

  void _refreshTransactionsStream() {
    final FinanceLocalRepository? repo = _repositoryForStreams;
    if (repo == null || _periodStartDate == null || _periodEndDate == null) {
      return;
    }
    _transactionsStream = repo.watchLedgerFinanceTransactionsInPeriod(
      startLocal: _mustStartDate(),
      endLocal: _mustEndDate(),
    );
  }

  void _moveCurrentDateByDays(int days) {
    setState(() {
      final DateTime nextCurrentDate = _normalizeDate(
        _mustCurrentDate().add(Duration(days: days)),
      );
      final Duration periodLength = _mustEndDate().difference(_mustStartDate());
      _currentDate = nextCurrentDate;
      _periodEndDate = nextCurrentDate;
      _periodStartDate = _normalizeDate(nextCurrentDate.subtract(periodLength));
      _refreshTransactionsStream();
    });
  }

  Future<void> _selectPeriodFromFilter() async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final DateTimeRange initialRange = DateTimeRange(
      start: _mustStartDate(),
      end: _mustEndDate(),
    );
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate = DateTime(2100);
    final DateTimeRange? selectedRange = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initialRange,
      helpText: l.transactionsFilterDialogTitle,
      saveText: l.commonSave,
    );
    if (selectedRange == null) {
      return;
    }
    setState(() {
      _periodStartDate = _normalizeDate(selectedRange.start);
      _periodEndDate = _normalizeDate(selectedRange.end);
      _currentDate = _periodEndDate;
      _refreshTransactionsStream();
    });
  }

  Future<void> _confirmDeleteTransaction(
    BuildContext context,
    FinanceTransaction row,
  ) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.deleteConfirmTitle),
        content: Text(l.deleteConfirmTransactionBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.deleteAction),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    try {
      await repo.deleteFinanceTransaction(row.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.errorWithMessage('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.transactionsTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l.transactionsFilterTooltip,
            onPressed: _selectPeriodFromFilter,
            icon: const Icon(Icons.filter_alt_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: l.transactionsPreviousDayTooltip,
                    onPressed: () => _moveCurrentDateByDays(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _currentDateFormat.format(_mustCurrentDate()),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${_dayFormat.format(_mustStartDate())} - '
                          '${_dayFormat.format(_mustEndDate())}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l.transactionsNextDayTooltip,
                    onPressed: () => _moveCurrentDateByDays(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_transactions',
        onPressed: () => context.push('/transactions/add'),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<FinanceTransaction>>(
        stream: _transactionsStream,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<FinanceTransaction>> snap,
            ) {
              if (!snap.hasData &&
                  snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('${snap.error}'));
              }
              final List<FinanceTransaction> rows =
                  snap.data ?? <FinanceTransaction>[];
              if (rows.isEmpty) {
                return Center(child: Text(l.transactionsEmpty));
              }
              return ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (BuildContext context, int _) =>
                    const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final FinanceTransaction t = rows[index];
                  final DateTime civil = localCivilDateFromFinanceEpochMillis(
                    t.dateUtcMillis,
                  );
                  final DateTime d = DateTime(
                    civil.year,
                    civil.month,
                    civil.day,
                  );
                  final TransactionType tt = TransactionType.parseStorage(
                    t.transactionType,
                  );
                  final PaymentMethod pm = PaymentMethod.parseStorage(
                    t.paymentMethod,
                  );
                  return ListTile(
                    leading: const Icon(Icons.receipt_outlined),
                    title: Text(t.description),
                    subtitle: Text(
                      '${_dayFormat.format(d)} · '
                      '${labelTransactionType(l, tt)} · '
                      '${labelPaymentMethod(l, pm)} · ${t.category}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          formatCents(t.amountInCents),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        PopupMenuButton<String>(
                          onSelected: (String value) {
                            if (value == 'edit') {
                              context.push('/transactions/edit/${t.id}');
                            }
                            if (value == 'delete') {
                              _confirmDeleteTransaction(context, t);
                            }
                          },
                          itemBuilder: (BuildContext ctx) =>
                              <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text(l.menuEdit),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text(l.menuDelete),
                                ),
                              ],
                        ),
                      ],
                    ),
                    onTap: () => context.push('/transactions/edit/${t.id}'),
                  );
                },
              );
            },
      ),
    );
  }
}
