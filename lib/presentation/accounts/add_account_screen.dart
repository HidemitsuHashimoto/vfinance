import 'package:flutter/material.dart';
import 'package:vfinance/app/pop_current_route.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/money.dart';
import 'package:vfinance/l10n/app_localizations.dart';

/// Creates an account with optional initial balance (centavos).
class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _balance = TextEditingController();
  String _type = 'checking';

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
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
      await repo.insertAccount(
        name: _name.text.trim(),
        type: _type,
        balanceInCents: cents,
      );
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
    return Scaffold(
      appBar: AppBar(title: Text(l.addAccountTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l.addAccountNameLabel),
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
              initialValue: _type,
              decoration: InputDecoration(labelText: l.addAccountTypeLabel),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem(
                  value: 'checking',
                  child: Text(l.accountTypeChecking),
                ),
                DropdownMenuItem(
                  value: 'savings',
                  child: Text(l.accountTypeSavings),
                ),
                DropdownMenuItem(value: 'cash', child: Text(l.accountTypeCash)),
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
          ],
        ),
      ),
    );
  }
}
