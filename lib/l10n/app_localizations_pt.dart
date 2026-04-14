// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'vfinance';

  @override
  String get navHome => 'Início';

  @override
  String get navAccounts => 'Contas';

  @override
  String get navTransactions => 'Lançamentos';

  @override
  String get navCards => 'Cartões';

  @override
  String get navBackup => 'Backup';

  @override
  String get homeTotalBalance => 'Saldo total';

  @override
  String homePaycheckPeriodTitle(int day) {
    return 'Saldo do período (pagamento dia $day)';
  }

  @override
  String homePaycheckInterval(String start, String end) {
    return '$start – $end';
  }

  @override
  String get homePaycheckBalanceFootnote =>
      'Contas menos faturas com vencimento entre essas datas. Em listas, pago/não pago é só informativo.';

  @override
  String get homePaycheckSummaryHeading => 'Resumo do período';

  @override
  String get homePaycheckEmptyTitle => 'Defina os dias de recebimento';

  @override
  String get homePaycheckEmptyBody =>
      'Adicione o(s) dia(s) do mês em que você recebe (ex.: 5 e 20) para ver o saldo e o fluxo de cada período de pagamento.';

  @override
  String get homePaycheckEmptyAction => 'Definir dias';

  @override
  String get homePaycheckConfigureTooltip => 'Dias de recebimento';

  @override
  String get homePaycheckDialogTitle => 'Dias de recebimento';

  @override
  String get homePaycheckDialogBody =>
      'Informe cada dia do mês em que costuma receber (1–31). Você pode ter vários dias.';

  @override
  String get homePaycheckDialogDayLabel => 'Dia (1–31)';

  @override
  String get homePaycheckDialogAdd => 'Adicionar';

  @override
  String get homePaycheckDialogDuplicateDay => 'Esse dia já está na lista.';

  @override
  String homeAccountsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contas',
      one: '$count conta',
    );
    return '$_temp0';
  }

  @override
  String homeInvoicesDueInPeriod(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faturas a vencer no período',
      one: '$count fatura a vencer no período',
    );
    return '$_temp0';
  }

  @override
  String get homePeriodIncome => 'Receitas no período';

  @override
  String get homePeriodImmediateExpenses =>
      'Despesas imediatas no período (exceto cartão)';

  @override
  String get cardsTitle => 'Cartões';

  @override
  String get cardsEmpty => 'Nenhum cartão. Toque em + para criar.';

  @override
  String get cardsNewExpense => 'Novo gasto';

  @override
  String get cardsAdjustInvoice => 'Ajustar fatura';

  @override
  String get cardsSheetAdjustInvoice => 'Ajustar fatura do ciclo';

  @override
  String get cardsAdjustInvoiceHint =>
      'O total da fatura vem dos gastos no cartão. Informe o valor ajustado se for diferente do que o banco cobrar.';

  @override
  String get cardsSaveAdjustment => 'Salvar ajuste';

  @override
  String get addCardExpenseTitle => 'Gasto no cartão';

  @override
  String get editCardExpenseTitle => 'Editar gasto no cartão';

  @override
  String get cardsNoInvoices => 'Sem faturas registradas';

  @override
  String cardsClosesOn(int day) {
    return 'Fecha dia $day';
  }

  @override
  String cardsDueOn(int day) {
    return 'Vence dia $day';
  }

  @override
  String cardsLimit(String amount) {
    return 'Limite $amount';
  }

  @override
  String cardsInvoiceCycleSummary(String start, String end, String due) {
    return 'Compras de $start a $end · Venc. $due';
  }

  @override
  String get cardsNoExpensesInCycle => 'Nenhum gasto neste ciclo';

  @override
  String cardsTotalAdjusted(String total, String adjusted) {
    return 'Total $total · Ajustado $adjusted';
  }

  @override
  String cardsTotalOnly(String total) {
    return 'Total $total';
  }

  @override
  String get cardsStatusOpen => 'Em aberto';

  @override
  String get cardsStatusPaid => 'Paga';

  @override
  String get cardsMonthField => 'Mês (1–12)';

  @override
  String get cardsYearField => 'Ano';

  @override
  String get cardsAdjustedField => 'Total ajustado (opcional, R\$)';

  @override
  String get cardsFilterTooltip => 'Filtrar por mês e ano do ciclo';

  @override
  String get cardsFilterDialogTitle => 'Mês e ano do ciclo';

  @override
  String get cardsFilterApply => 'Aplicar';

  @override
  String get cardsMonthPickerLabel => 'Mês';

  @override
  String get cardsNoInvoiceInSelectedMonth =>
      'Nenhuma fatura neste mês de ciclo';

  @override
  String get transactionsTitle => 'Lançamentos';

  @override
  String get transactionsEmpty =>
      'Nenhum lançamento. Toque em + para adicionar.';

  @override
  String get transactionsFilterTooltip => 'Filtrar por período';

  @override
  String get transactionsFilterDialogTitle => 'Período dos lançamentos';

  @override
  String get transactionsPreviousDayTooltip => 'Dia anterior';

  @override
  String get transactionsNextDayTooltip => 'Próximo dia';

  @override
  String get accountsTitle => 'Contas';

  @override
  String get accountsEmpty => 'Nenhuma conta. Toque em + para criar.';

  @override
  String get addAccountTitle => 'Nova conta';

  @override
  String get addAccountNameLabel => 'Nome';

  @override
  String get addAccountTypeLabel => 'Tipo';

  @override
  String get addAccountBalanceLabel => 'Saldo inicial (opcional)';

  @override
  String get accountTypeChecking => 'Conta corrente';

  @override
  String get accountTypeSavings => 'Poupança';

  @override
  String get accountTypeCash => 'Dinheiro';

  @override
  String get addCardTitle => 'Novo cartão';

  @override
  String get addCardNameLabel => 'Nome';

  @override
  String get addCardLimitLabel => 'Limite (R\$)';

  @override
  String get addCardClosingLabel => 'Dia de fechamento (1–31)';

  @override
  String get addCardDueLabel => 'Dia de vencimento (1–31)';

  @override
  String get addTransactionTitle => 'Novo lançamento';

  @override
  String get addTransactionPaymentMethod => 'Meio de pagamento';

  @override
  String get addTransactionExpense => 'Despesa';

  @override
  String get addTransactionIncome => 'Receita';

  @override
  String get addTransactionAmountLabel => 'Valor (R\$)';

  @override
  String get addCardExpenseInstallmentsLabel => 'Parcelas';

  @override
  String get addCardExpenseInstallmentsHint =>
      'O valor acima é o total; divide em parcelas iguais (1 = à vista).';

  @override
  String addCardExpenseInstallmentLineDescription(
    String base,
    int current,
    int total,
  ) {
    return '$base · Parcela $current de $total';
  }

  @override
  String get validationInstallmentsRange =>
      'Informe um número de parcelas entre 1 e 60.';

  @override
  String get addTransactionCategoryLabel => 'Categoria';

  @override
  String get addTransactionDescriptionLabel => 'Descrição';

  @override
  String get addTransactionDateLabel => 'Data';

  @override
  String get addTransactionAccountLabel => 'Conta';

  @override
  String get addTransactionCardLabel => 'Cartão';

  @override
  String get paymentPix => 'Pix';

  @override
  String get paymentDebit => 'Débito';

  @override
  String get paymentCredit => 'Crédito';

  @override
  String get paymentBoleto => 'Boleto';

  @override
  String get transactionKindExpense => 'Despesa';

  @override
  String get transactionKindIncome => 'Receita';

  @override
  String get commonSave => 'Salvar';

  @override
  String get menuEdit => 'Editar';

  @override
  String get menuDelete => 'Excluir';

  @override
  String get deleteAction => 'Excluir';

  @override
  String get deleteConfirmTitle => 'Confirmar exclusão';

  @override
  String get deleteConfirmAccountBody =>
      'Excluir esta conta? Só é possível se não houver lançamentos vinculados a ela.';

  @override
  String get deleteConfirmCardBody =>
      'Excluir este cartão? Só é possível se não houver lançamentos nem faturas vinculados.';

  @override
  String get deleteConfirmTransactionBody =>
      'Excluir este lançamento? O saldo da conta e totais de fatura serão ajustados.';

  @override
  String get deleteConfirmCardExpenseBody =>
      'Excluir este gasto no cartão? O total da fatura será recalculado.';

  @override
  String get editAccountTitle => 'Editar conta';

  @override
  String get editCardTitle => 'Editar cartão';

  @override
  String get editTransactionTitle => 'Editar lançamento';

  @override
  String get errorDeleteAccountBlocked =>
      'Não é possível excluir: existem lançamentos usando esta conta.';

  @override
  String get errorDeleteCardBlocked =>
      'Não é possível excluir: existem lançamentos ou faturas usando este cartão.';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonExport => 'Exportar…';

  @override
  String get commonImport => 'Importar arquivo…';

  @override
  String get validationNameRequired => 'Informe o nome';

  @override
  String get validationCategoryRequired => 'Informe a categoria';

  @override
  String get validationDescriptionRequired => 'Informe a descrição';

  @override
  String get validationValueRequired => 'Informe o valor';

  @override
  String get validationInvalidValue => 'Valor inválido';

  @override
  String get validationInvalidMonth => 'Mês inválido';

  @override
  String get validationInvalidYear => 'Ano inválido';

  @override
  String get validationTotalRequired => 'Informe o total';

  @override
  String get validationLimitRequired => 'Informe o limite';

  @override
  String get validationInvalidNumber => 'Número inválido';

  @override
  String get validationBalanceHint => 'Valor inválido (use 10,50 ou 10.50)';

  @override
  String get registerAccountFirst => 'Cadastre uma conta primeiro.';

  @override
  String get registerCardFirst => 'Cadastre um cartão primeiro.';

  @override
  String get daysInvalidRange => 'Dias devem estar entre 1 e 31.';

  @override
  String errorWithMessage(String message) {
    return 'Erro: $message';
  }

  @override
  String errorSaveAccount(String message) {
    return 'Erro ao salvar: $message';
  }

  @override
  String get backupTitle => 'Backup';

  @override
  String get backupSectionTitle => 'Backup por ano (JSON)';

  @override
  String backupDescription(String fileName) {
    return 'Exporta ou restaura dados de um ano civil. Nome sugerido: $fileName.';
  }

  @override
  String get backupYearLabel => 'Ano do backup';

  @override
  String get backupSaveDialogTitle => 'Salvar backup';

  @override
  String get backupGenerated => 'Backup gerado. Escolha onde salvar.';

  @override
  String backupExportFailed(String message) {
    return 'Falha ao exportar: $message';
  }

  @override
  String get backupReadFailed => 'Não foi possível ler o arquivo.';

  @override
  String backupInvalidJson(String message) {
    return 'JSON inválido: $message';
  }

  @override
  String get restoreDialogTitle => 'Restaurar backup?';

  @override
  String restoreDialogBody(int year) {
    return 'Os lançamentos e faturas de $year serão substituídos pelos dados do arquivo. Outros anos não são alterados.';
  }

  @override
  String get restoreAction => 'Restaurar';

  @override
  String restoreDone(int year) {
    return 'Dados de $year restaurados.';
  }

  @override
  String restoreFailed(String message) {
    return 'Falha ao importar: $message';
  }

  @override
  String get backupDebugClearSectionTitle => 'Desenvolvimento (debug)';

  @override
  String get backupDebugClearDescription =>
      'Apaga todas as contas, cartões, lançamentos e faturas neste aparelho. Só aparece em builds de debug.';

  @override
  String get backupDebugClearButton => 'Limpar todos os dados locais';

  @override
  String get backupDebugClearConfirmTitle => 'Limpar tudo?';

  @override
  String get backupDebugClearConfirmBody =>
      'Esta ação não pode ser desfeita. Exporte um backup antes, se precisar dos dados.';

  @override
  String get backupDebugClearDone => 'Dados locais apagados.';

  @override
  String backupDebugClearFailed(String message) {
    return 'Falha ao limpar: $message';
  }
}
