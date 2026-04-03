import 'package:flutter/material.dart';
import 'package:vfinance/app/pop_current_route.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/money.dart';

/// Registers a credit card (closing / due days as in [domain.md]).
class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

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

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    _closing.dispose();
    _due.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dias devem estar entre 1 e 31.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await repo.insertCreditCard(
        name: _name.text.trim(),
        limitInCents: Money.parseReais(_limit.text).cents,
        closingDay: closing,
        dueDay: due,
      );
      if (context.mounted) {
        popCurrentRoute(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo cartão')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _limit,
              decoration: const InputDecoration(
                labelText: 'Limite (R\$)',
                hintText: '0,00',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (String? v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Informe o limite';
                }
                try {
                  Money.parseReais(v);
                } catch (_) {
                  return 'Valor inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _closing,
              decoration: const InputDecoration(
                labelText: 'Dia de fechamento (1–31)',
              ),
              keyboardType: TextInputType.number,
              validator: (String? v) {
                if (v == null || int.tryParse(v.trim()) == null) {
                  return 'Número inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _due,
              decoration: const InputDecoration(
                labelText: 'Dia de vencimento (1–31)',
              ),
              keyboardType: TextInputType.number,
              validator: (String? v) {
                if (v == null || int.tryParse(v.trim()) == null) {
                  return 'Número inválido';
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
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
