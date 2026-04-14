import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'vfinance'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get navHome;

  /// No description provided for @navAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Contas'**
  String get navAccounts;

  /// No description provided for @navTransactions.
  ///
  /// In pt, this message translates to:
  /// **'Lançamentos'**
  String get navTransactions;

  /// No description provided for @navCards.
  ///
  /// In pt, this message translates to:
  /// **'Cartões'**
  String get navCards;

  /// No description provided for @navBackup.
  ///
  /// In pt, this message translates to:
  /// **'Backup'**
  String get navBackup;

  /// No description provided for @homeTotalBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo total'**
  String get homeTotalBalance;

  /// No description provided for @homePaycheckPeriodTitle.
  ///
  /// In pt, this message translates to:
  /// **'Saldo do período (pagamento dia {day})'**
  String homePaycheckPeriodTitle(int day);

  /// No description provided for @homePaycheckInterval.
  ///
  /// In pt, this message translates to:
  /// **'{start} – {end}'**
  String homePaycheckInterval(String start, String end);

  /// No description provided for @homePaycheckBalanceFootnote.
  ///
  /// In pt, this message translates to:
  /// **'Contas menos faturas com vencimento entre essas datas. Em listas, pago/não pago é só informativo.'**
  String get homePaycheckBalanceFootnote;

  /// No description provided for @homePaycheckSummaryHeading.
  ///
  /// In pt, this message translates to:
  /// **'Resumo do período'**
  String get homePaycheckSummaryHeading;

  /// No description provided for @homePaycheckEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Defina os dias de recebimento'**
  String get homePaycheckEmptyTitle;

  /// No description provided for @homePaycheckEmptyBody.
  ///
  /// In pt, this message translates to:
  /// **'Adicione o(s) dia(s) do mês em que você recebe (ex.: 5 e 20) para ver o saldo e o fluxo de cada período de pagamento.'**
  String get homePaycheckEmptyBody;

  /// No description provided for @homePaycheckEmptyAction.
  ///
  /// In pt, this message translates to:
  /// **'Definir dias'**
  String get homePaycheckEmptyAction;

  /// No description provided for @homePaycheckConfigureTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Dias de recebimento'**
  String get homePaycheckConfigureTooltip;

  /// No description provided for @homePaycheckDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dias de recebimento'**
  String get homePaycheckDialogTitle;

  /// No description provided for @homePaycheckDialogBody.
  ///
  /// In pt, this message translates to:
  /// **'Informe cada dia do mês em que costuma receber (1–31). Você pode ter vários dias.'**
  String get homePaycheckDialogBody;

  /// No description provided for @homePaycheckDialogDayLabel.
  ///
  /// In pt, this message translates to:
  /// **'Dia (1–31)'**
  String get homePaycheckDialogDayLabel;

  /// No description provided for @homePaycheckDialogAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get homePaycheckDialogAdd;

  /// No description provided for @homePaycheckDialogDuplicateDay.
  ///
  /// In pt, this message translates to:
  /// **'Esse dia já está na lista.'**
  String get homePaycheckDialogDuplicateDay;

  /// No description provided for @homeAccountsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{{count} conta} other{{count} contas}}'**
  String homeAccountsCount(int count);

  /// No description provided for @homeInvoicesDueInPeriod.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{{count} fatura a vencer no período} other{{count} faturas a vencer no período}}'**
  String homeInvoicesDueInPeriod(int count);

  /// No description provided for @homePeriodIncome.
  ///
  /// In pt, this message translates to:
  /// **'Receitas no período'**
  String get homePeriodIncome;

  /// No description provided for @homePeriodImmediateExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Despesas imediatas no período (exceto cartão)'**
  String get homePeriodImmediateExpenses;

  /// No description provided for @cardsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cartões'**
  String get cardsTitle;

  /// No description provided for @cardsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum cartão. Toque em + para criar.'**
  String get cardsEmpty;

  /// No description provided for @cardsNewExpense.
  ///
  /// In pt, this message translates to:
  /// **'Novo gasto'**
  String get cardsNewExpense;

  /// No description provided for @cardsAdjustInvoice.
  ///
  /// In pt, this message translates to:
  /// **'Ajustar fatura'**
  String get cardsAdjustInvoice;

  /// No description provided for @cardsSheetAdjustInvoice.
  ///
  /// In pt, this message translates to:
  /// **'Ajustar fatura do ciclo'**
  String get cardsSheetAdjustInvoice;

  /// No description provided for @cardsAdjustInvoiceHint.
  ///
  /// In pt, this message translates to:
  /// **'O total da fatura vem dos gastos no cartão. Informe o valor ajustado se for diferente do que o banco cobrar.'**
  String get cardsAdjustInvoiceHint;

  /// No description provided for @cardsSaveAdjustment.
  ///
  /// In pt, this message translates to:
  /// **'Salvar ajuste'**
  String get cardsSaveAdjustment;

  /// No description provided for @addCardExpenseTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gasto no cartão'**
  String get addCardExpenseTitle;

  /// No description provided for @editCardExpenseTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar gasto no cartão'**
  String get editCardExpenseTitle;

  /// No description provided for @cardsNoInvoices.
  ///
  /// In pt, this message translates to:
  /// **'Sem faturas registradas'**
  String get cardsNoInvoices;

  /// No description provided for @cardsClosesOn.
  ///
  /// In pt, this message translates to:
  /// **'Fecha dia {day}'**
  String cardsClosesOn(int day);

  /// No description provided for @cardsDueOn.
  ///
  /// In pt, this message translates to:
  /// **'Vence dia {day}'**
  String cardsDueOn(int day);

  /// No description provided for @cardsLimit.
  ///
  /// In pt, this message translates to:
  /// **'Limite {amount}'**
  String cardsLimit(String amount);

  /// No description provided for @cardsInvoiceCycleSummary.
  ///
  /// In pt, this message translates to:
  /// **'Compras de {start} a {end} · Venc. {due}'**
  String cardsInvoiceCycleSummary(String start, String end, String due);

  /// No description provided for @cardsNoExpensesInCycle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum gasto neste ciclo'**
  String get cardsNoExpensesInCycle;

  /// No description provided for @cardsTotalAdjusted.
  ///
  /// In pt, this message translates to:
  /// **'Total {total} · Ajustado {adjusted}'**
  String cardsTotalAdjusted(String total, String adjusted);

  /// No description provided for @cardsTotalOnly.
  ///
  /// In pt, this message translates to:
  /// **'Total {total}'**
  String cardsTotalOnly(String total);

  /// No description provided for @cardsStatusOpen.
  ///
  /// In pt, this message translates to:
  /// **'Em aberto'**
  String get cardsStatusOpen;

  /// No description provided for @cardsStatusPaid.
  ///
  /// In pt, this message translates to:
  /// **'Paga'**
  String get cardsStatusPaid;

  /// No description provided for @cardsMonthField.
  ///
  /// In pt, this message translates to:
  /// **'Mês (1–12)'**
  String get cardsMonthField;

  /// No description provided for @cardsYearField.
  ///
  /// In pt, this message translates to:
  /// **'Ano'**
  String get cardsYearField;

  /// No description provided for @cardsAdjustedField.
  ///
  /// In pt, this message translates to:
  /// **'Total ajustado (opcional, R\$)'**
  String get cardsAdjustedField;

  /// No description provided for @cardsFilterTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar por mês e ano do ciclo'**
  String get cardsFilterTooltip;

  /// No description provided for @cardsFilterDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mês e ano do ciclo'**
  String get cardsFilterDialogTitle;

  /// No description provided for @cardsFilterApply.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar'**
  String get cardsFilterApply;

  /// No description provided for @cardsMonthPickerLabel.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get cardsMonthPickerLabel;

  /// No description provided for @cardsNoInvoiceInSelectedMonth.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma fatura neste mês de ciclo'**
  String get cardsNoInvoiceInSelectedMonth;

  /// No description provided for @transactionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lançamentos'**
  String get transactionsTitle;

  /// No description provided for @transactionsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum lançamento. Toque em + para adicionar.'**
  String get transactionsEmpty;

  /// No description provided for @transactionsFilterTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar por período'**
  String get transactionsFilterTooltip;

  /// No description provided for @transactionsFilterDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Período dos lançamentos'**
  String get transactionsFilterDialogTitle;

  /// No description provided for @transactionsPreviousDayTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Dia anterior'**
  String get transactionsPreviousDayTooltip;

  /// No description provided for @transactionsNextDayTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Próximo dia'**
  String get transactionsNextDayTooltip;

  /// No description provided for @accountsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Contas'**
  String get accountsTitle;

  /// No description provided for @accountsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conta. Toque em + para criar.'**
  String get accountsEmpty;

  /// No description provided for @addAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova conta'**
  String get addAccountTitle;

  /// No description provided for @addAccountNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get addAccountNameLabel;

  /// No description provided for @addAccountTypeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get addAccountTypeLabel;

  /// No description provided for @addAccountBalanceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Saldo inicial (opcional)'**
  String get addAccountBalanceLabel;

  /// No description provided for @accountTypeChecking.
  ///
  /// In pt, this message translates to:
  /// **'Conta corrente'**
  String get accountTypeChecking;

  /// No description provided for @accountTypeSavings.
  ///
  /// In pt, this message translates to:
  /// **'Poupança'**
  String get accountTypeSavings;

  /// No description provided for @accountTypeCash.
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro'**
  String get accountTypeCash;

  /// No description provided for @addCardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo cartão'**
  String get addCardTitle;

  /// No description provided for @addCardNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get addCardNameLabel;

  /// No description provided for @addCardLimitLabel.
  ///
  /// In pt, this message translates to:
  /// **'Limite (R\$)'**
  String get addCardLimitLabel;

  /// No description provided for @addCardClosingLabel.
  ///
  /// In pt, this message translates to:
  /// **'Dia de fechamento (1–31)'**
  String get addCardClosingLabel;

  /// No description provided for @addCardDueLabel.
  ///
  /// In pt, this message translates to:
  /// **'Dia de vencimento (1–31)'**
  String get addCardDueLabel;

  /// No description provided for @addTransactionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo lançamento'**
  String get addTransactionTitle;

  /// No description provided for @addTransactionPaymentMethod.
  ///
  /// In pt, this message translates to:
  /// **'Meio de pagamento'**
  String get addTransactionPaymentMethod;

  /// No description provided for @addTransactionExpense.
  ///
  /// In pt, this message translates to:
  /// **'Despesa'**
  String get addTransactionExpense;

  /// No description provided for @addTransactionIncome.
  ///
  /// In pt, this message translates to:
  /// **'Receita'**
  String get addTransactionIncome;

  /// No description provided for @addTransactionAmountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor (R\$)'**
  String get addTransactionAmountLabel;

  /// No description provided for @addCardExpenseInstallmentsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Parcelas'**
  String get addCardExpenseInstallmentsLabel;

  /// No description provided for @addCardExpenseInstallmentsHint.
  ///
  /// In pt, this message translates to:
  /// **'O valor acima é o total; divide em parcelas iguais (1 = à vista).'**
  String get addCardExpenseInstallmentsHint;

  /// No description provided for @addCardExpenseInstallmentLineDescription.
  ///
  /// In pt, this message translates to:
  /// **'{base} · Parcela {current} de {total}'**
  String addCardExpenseInstallmentLineDescription(
    String base,
    int current,
    int total,
  );

  /// No description provided for @validationInstallmentsRange.
  ///
  /// In pt, this message translates to:
  /// **'Informe um número de parcelas entre 1 e 60.'**
  String get validationInstallmentsRange;

  /// No description provided for @addTransactionCategoryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get addTransactionCategoryLabel;

  /// No description provided for @addTransactionDescriptionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get addTransactionDescriptionLabel;

  /// No description provided for @addTransactionDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get addTransactionDateLabel;

  /// No description provided for @addTransactionAccountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get addTransactionAccountLabel;

  /// No description provided for @addTransactionCardLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cartão'**
  String get addTransactionCardLabel;

  /// No description provided for @paymentPix.
  ///
  /// In pt, this message translates to:
  /// **'Pix'**
  String get paymentPix;

  /// No description provided for @paymentDebit.
  ///
  /// In pt, this message translates to:
  /// **'Débito'**
  String get paymentDebit;

  /// No description provided for @paymentCredit.
  ///
  /// In pt, this message translates to:
  /// **'Crédito'**
  String get paymentCredit;

  /// No description provided for @paymentBoleto.
  ///
  /// In pt, this message translates to:
  /// **'Boleto'**
  String get paymentBoleto;

  /// No description provided for @transactionKindExpense.
  ///
  /// In pt, this message translates to:
  /// **'Despesa'**
  String get transactionKindExpense;

  /// No description provided for @transactionKindIncome.
  ///
  /// In pt, this message translates to:
  /// **'Receita'**
  String get transactionKindIncome;

  /// No description provided for @commonSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get commonSave;

  /// No description provided for @menuEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get menuEdit;

  /// No description provided for @menuDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get menuDelete;

  /// No description provided for @deleteAction.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get deleteAction;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar exclusão'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmAccountBody.
  ///
  /// In pt, this message translates to:
  /// **'Excluir esta conta? Só é possível se não houver lançamentos vinculados a ela.'**
  String get deleteConfirmAccountBody;

  /// No description provided for @deleteConfirmCardBody.
  ///
  /// In pt, this message translates to:
  /// **'Excluir este cartão? Só é possível se não houver lançamentos nem faturas vinculados.'**
  String get deleteConfirmCardBody;

  /// No description provided for @deleteConfirmTransactionBody.
  ///
  /// In pt, this message translates to:
  /// **'Excluir este lançamento? O saldo da conta e totais de fatura serão ajustados.'**
  String get deleteConfirmTransactionBody;

  /// No description provided for @deleteConfirmCardExpenseBody.
  ///
  /// In pt, this message translates to:
  /// **'Excluir este gasto no cartão? O total da fatura será recalculado.'**
  String get deleteConfirmCardExpenseBody;

  /// No description provided for @editAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar conta'**
  String get editAccountTitle;

  /// No description provided for @editCardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar cartão'**
  String get editCardTitle;

  /// No description provided for @editTransactionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar lançamento'**
  String get editTransactionTitle;

  /// No description provided for @errorDeleteAccountBlocked.
  ///
  /// In pt, this message translates to:
  /// **'Não é possível excluir: existem lançamentos usando esta conta.'**
  String get errorDeleteAccountBlocked;

  /// No description provided for @errorDeleteCardBlocked.
  ///
  /// In pt, this message translates to:
  /// **'Não é possível excluir: existem lançamentos ou faturas usando este cartão.'**
  String get errorDeleteCardBlocked;

  /// No description provided for @commonCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonExport.
  ///
  /// In pt, this message translates to:
  /// **'Exportar…'**
  String get commonExport;

  /// No description provided for @commonImport.
  ///
  /// In pt, this message translates to:
  /// **'Importar arquivo…'**
  String get commonImport;

  /// No description provided for @validationNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome'**
  String get validationNameRequired;

  /// No description provided for @validationCategoryRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe a categoria'**
  String get validationCategoryRequired;

  /// No description provided for @validationDescriptionRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe a descrição'**
  String get validationDescriptionRequired;

  /// No description provided for @validationValueRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o valor'**
  String get validationValueRequired;

  /// No description provided for @validationInvalidValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor inválido'**
  String get validationInvalidValue;

  /// No description provided for @validationInvalidMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês inválido'**
  String get validationInvalidMonth;

  /// No description provided for @validationInvalidYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano inválido'**
  String get validationInvalidYear;

  /// No description provided for @validationTotalRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o total'**
  String get validationTotalRequired;

  /// No description provided for @validationLimitRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o limite'**
  String get validationLimitRequired;

  /// No description provided for @validationInvalidNumber.
  ///
  /// In pt, this message translates to:
  /// **'Número inválido'**
  String get validationInvalidNumber;

  /// No description provided for @validationBalanceHint.
  ///
  /// In pt, this message translates to:
  /// **'Valor inválido (use 10,50 ou 10.50)'**
  String get validationBalanceHint;

  /// No description provided for @registerAccountFirst.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre uma conta primeiro.'**
  String get registerAccountFirst;

  /// No description provided for @registerCardFirst.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre um cartão primeiro.'**
  String get registerCardFirst;

  /// No description provided for @daysInvalidRange.
  ///
  /// In pt, this message translates to:
  /// **'Dias devem estar entre 1 e 31.'**
  String get daysInvalidRange;

  /// No description provided for @errorWithMessage.
  ///
  /// In pt, this message translates to:
  /// **'Erro: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @errorSaveAccount.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar: {message}'**
  String errorSaveAccount(String message);

  /// No description provided for @backupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Backup'**
  String get backupTitle;

  /// No description provided for @backupSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Backup por ano (JSON)'**
  String get backupSectionTitle;

  /// No description provided for @backupDescription.
  ///
  /// In pt, this message translates to:
  /// **'Exporta ou restaura dados de um ano civil. Nome sugerido: {fileName}.'**
  String backupDescription(String fileName);

  /// No description provided for @backupYearLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ano do backup'**
  String get backupYearLabel;

  /// No description provided for @backupSaveDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Salvar backup'**
  String get backupSaveDialogTitle;

  /// No description provided for @backupGenerated.
  ///
  /// In pt, this message translates to:
  /// **'Backup gerado. Escolha onde salvar.'**
  String get backupGenerated;

  /// No description provided for @backupExportFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao exportar: {message}'**
  String backupExportFailed(String message);

  /// No description provided for @backupReadFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível ler o arquivo.'**
  String get backupReadFailed;

  /// No description provided for @backupInvalidJson.
  ///
  /// In pt, this message translates to:
  /// **'JSON inválido: {message}'**
  String backupInvalidJson(String message);

  /// No description provided for @restoreDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar backup?'**
  String get restoreDialogTitle;

  /// No description provided for @restoreDialogBody.
  ///
  /// In pt, this message translates to:
  /// **'Os lançamentos e faturas de {year} serão substituídos pelos dados do arquivo. Outros anos não são alterados.'**
  String restoreDialogBody(int year);

  /// No description provided for @restoreAction.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get restoreAction;

  /// No description provided for @restoreDone.
  ///
  /// In pt, this message translates to:
  /// **'Dados de {year} restaurados.'**
  String restoreDone(int year);

  /// No description provided for @restoreFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao importar: {message}'**
  String restoreFailed(String message);

  /// No description provided for @backupDebugClearSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desenvolvimento (debug)'**
  String get backupDebugClearSectionTitle;

  /// No description provided for @backupDebugClearDescription.
  ///
  /// In pt, this message translates to:
  /// **'Apaga todas as contas, cartões, lançamentos e faturas neste aparelho. Só aparece em builds de debug.'**
  String get backupDebugClearDescription;

  /// No description provided for @backupDebugClearButton.
  ///
  /// In pt, this message translates to:
  /// **'Limpar todos os dados locais'**
  String get backupDebugClearButton;

  /// No description provided for @backupDebugClearConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Limpar tudo?'**
  String get backupDebugClearConfirmTitle;

  /// No description provided for @backupDebugClearConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação não pode ser desfeita. Exporte um backup antes, se precisar dos dados.'**
  String get backupDebugClearConfirmBody;

  /// No description provided for @backupDebugClearDone.
  ///
  /// In pt, this message translates to:
  /// **'Dados locais apagados.'**
  String get backupDebugClearDone;

  /// No description provided for @backupDebugClearFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao limpar: {message}'**
  String backupDebugClearFailed(String message);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
