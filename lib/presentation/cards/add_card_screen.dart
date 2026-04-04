import 'package:flutter/material.dart';
import 'package:vfinance/app/pop_current_route.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/delete_blocked_exceptions.dart';
import 'package:vfinance/domain/money.dart';
import 'package:vfinance/l10n/app_localizations.dart';
import 'package:vfinance/presentation/formatting/amount_format.dart';

/// Creates or edits a credit card (closing / due days as in [domain.md]).
class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key, this.cardId});

  /// When set, loads the card and updates on save.
  final int? cardId;

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _limit = TextEditingController();
  final TextEditingController _closing = TextEditingController();
  final TextEditingController _due = TextEditingController();
  bool _isSaving = false;
  bool _isLoadingEdit = false;
  bool _didStartLoad = false;

  @override
  void initState() {
    super.initState();
    _isLoadingEdit = widget.cardId != null;
  }

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    _closing.dispose();
    _due.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.cardId != null && !_didStartLoad) {
      _didStartLoad = true;
      final FinanceLocalRepository repo = VfinanceScope.of(context);
      repo.getCreditCardById(widget.cardId!).then((CreditCard? c) {
        if (!mounted) {
          return;
        }
        if (c == null) {
          popCurrentRoute(context);
          return;
        }
        setState(() {
          _isLoadingEdit = false;
          _name.text = c.name;
          _limit.text = formatCentsAsReaisInput(c.limitInCents);
          _closing.text = '${c.closingDay}';
          _due.text = '${c.dueDay}';
        });
      });
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.deleteConfirmTitle),
        content: Text(l.deleteConfirmCardBody),
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
      await repo.deleteCreditCard(widget.cardId!);
      if (context.mounted) {
        popCurrentRoute(context);
      }
    } on CardDeleteBlockedException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.errorDeleteCardBlocked)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.errorWithMessage('$e'))));
      }
    }
  }

  Future<void> _submit(BuildContext context) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    if (_isSaving) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    final int closing = int.parse(_closing.text.trim());
    final int due = int.parse(_due.text.trim());
    if (closing < 1 || closing > 31 || due < 1 || due > 31) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.daysInvalidRange)));
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (widget.cardId == null) {
        await repo.insertCreditCard(
          name: _name.text.trim(),
          limitInCents: Money.parseReais(_limit.text).cents,
          closingDay: closing,
          dueDay: due,
        );
      } else {
        await repo.updateCreditCard(
          id: widget.cardId!,
          name: _name.text.trim(),
          limitInCents: Money.parseReais(_limit.text).cents,
          closingDay: closing,
          dueDay: due,
        );
      }
      if (context.mounted) {
        popCurrentRoute(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.errorWithMessage('$e'))));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool isEdit = widget.cardId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? l.editCardTitle : l.addCardTitle)),
      body: _isLoadingEdit
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(labelText: l.addCardNameLabel),
                    validator: (String? v) => (v == null || v.trim().isEmpty)
                        ? l.validationNameRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _limit,
                    decoration: InputDecoration(
                      labelText: l.addCardLimitLabel,
                      hintText: '0,00',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (String? v) {
                      if (v == null || v.trim().isEmpty) {
                        return l.validationLimitRequired;
                      }
                      try {
                        Money.parseReais(v);
                      } catch (_) {
                        return l.validationInvalidValue;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _closing,
                    decoration: InputDecoration(
                      labelText: l.addCardClosingLabel,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (String? v) {
                      if (v == null || int.tryParse(v.trim()) == null) {
                        return l.validationInvalidNumber;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _due,
                    decoration: InputDecoration(labelText: l.addCardDueLabel),
                    keyboardType: TextInputType.number,
                    validator: (String? v) {
                      if (v == null || int.tryParse(v.trim()) == null) {
                        return l.validationInvalidNumber;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSaving ? null : () => _submit(context),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l.commonSave),
                  ),
                  if (isEdit) ...<Widget>[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => _confirmDelete(context),
                      child: Text(
                        l.menuDelete,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
