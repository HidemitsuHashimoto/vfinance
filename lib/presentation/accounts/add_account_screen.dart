import 'package:flutter/material.dart';
import 'package:vfinance/app/pop_current_route.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/delete_blocked_exceptions.dart';
import 'package:vfinance/domain/money.dart';
import 'package:vfinance/l10n/app_localizations.dart';
import 'package:vfinance/presentation/formatting/amount_format.dart';

/// Creates or edits an account with optional balance (centavos).
class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key, this.accountId});

  /// When set, loads the account and updates on save.
  final int? accountId;

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _balance = TextEditingController();
  String _type = 'checking';
  bool _isLoadingEdit = false;
  bool _didStartLoad = false;

  @override
  void initState() {
    super.initState();
    _isLoadingEdit = widget.accountId != null;
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.accountId != null && !_didStartLoad) {
      _didStartLoad = true;
      final FinanceLocalRepository repo = VfinanceScope.of(context);
      repo.getAccountById(widget.accountId!).then((Account? a) {
        if (!mounted) {
          return;
        }
        if (a == null) {
          popCurrentRoute(context);
          return;
        }
        setState(() {
          _isLoadingEdit = false;
          _name.text = a.name;
          _type = a.type;
          _balance.text = formatCentsAsReaisInput(a.balanceInCents);
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
        content: Text(l.deleteConfirmAccountBody),
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
      await repo.deleteAccount(widget.accountId!);
      if (context.mounted) {
        popCurrentRoute(context);
      }
    } on AccountDeleteBlockedException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.errorDeleteAccountBlocked)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.errorSaveAccount('$e'))));
      }
    }
  }

  Future<void> _submit(BuildContext context) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    final int cents = _balance.text.trim().isEmpty
        ? 0
        : Money.parseReais(_balance.text).cents;
    try {
      if (widget.accountId == null) {
        await repo.insertAccount(
          name: _name.text.trim(),
          type: _type,
          balanceInCents: cents,
        );
      } else {
        await repo.updateAccount(
          id: widget.accountId!,
          name: _name.text.trim(),
          type: _type,
          balanceInCents: cents,
        );
      }
      if (context.mounted) {
        popCurrentRoute(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.errorSaveAccount('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool isEdit = widget.accountId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l.editAccountTitle : l.addAccountTitle),
      ),
      body: _isLoadingEdit
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: l.addAccountNameLabel,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (String? v) {
                      if (v == null || v.trim().isEmpty) {
                        return l.validationNameRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>(_type),
                    initialValue: _type,
                    decoration: InputDecoration(
                      labelText: l.addAccountTypeLabel,
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: 'checking',
                        child: Text(l.accountTypeChecking),
                      ),
                      DropdownMenuItem(
                        value: 'savings',
                        child: Text(l.accountTypeSavings),
                      ),
                      DropdownMenuItem(
                        value: 'cash',
                        child: Text(l.accountTypeCash),
                      ),
                    ],
                    onChanged: (String? v) {
                      if (v != null) {
                        setState(() => _type = v);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _balance,
                    decoration: InputDecoration(
                      labelText: l.addAccountBalanceLabel,
                      hintText: '0,00',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (String? v) {
                      if (v == null || v.trim().isEmpty) {
                        return null;
                      }
                      try {
                        Money.parseReais(v);
                      } catch (_) {
                        return l.validationBalanceHint;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => _submit(context),
                    child: Text(l.commonSave),
                  ),
                  if (isEdit) ...<Widget>[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => _confirmDelete(context),
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
