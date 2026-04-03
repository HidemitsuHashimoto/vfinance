import 'dart:convert';

import 'package:vfinance/domain/year_backup_snapshot.dart';

const int _kSupportedBackupSchemaVersion = 1;

/// Serializes [snapshot] to JSON (centavos and enum storage strings).
String encodeYearBackupSnapshot(YearBackupSnapshot snapshot) {
  return jsonEncode(_snapshotToJson(snapshot));
}

/// Parses JSON produced by [encodeYearBackupSnapshot].
YearBackupSnapshot decodeYearBackupSnapshot(String jsonText) {
  final Object? decoded = jsonDecode(jsonText);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Backup root must be a JSON object');
  }
  return _snapshotFromJson(decoded);
}

Map<String, dynamic> _snapshotToJson(YearBackupSnapshot s) {
  return <String, dynamic>{
    'schemaVersion': s.schemaVersion,
    'year': s.year,
    'accounts': s.accounts.map(_accountToJson).toList(),
    'creditCards': s.creditCards.map(_creditCardToJson).toList(),
    'financeTransactions': s.financeTransactions
        .map(_financeTransactionToJson)
        .toList(),
    'invoices': s.invoices.map(_invoiceToJson).toList(),
  };
}

YearBackupSnapshot _snapshotFromJson(Map<String, dynamic> m) {
  final int schemaVersion = _readInt(m, 'schemaVersion');
  if (schemaVersion != _kSupportedBackupSchemaVersion) {
    throw FormatException('Unsupported backup schemaVersion: $schemaVersion');
  }
  final int year = _readInt(m, 'year');
  final List<YearBackupAccount> accounts = _readList(
    m,
    'accounts',
    (Map<String, dynamic> e) => _accountFromJson(e),
  );
  final List<YearBackupCreditCard> cards = _readList(
    m,
    'creditCards',
    (Map<String, dynamic> e) => _creditCardFromJson(e),
  );
  final List<YearBackupFinanceTransaction> tx = _readList(
    m,
    'financeTransactions',
    (Map<String, dynamic> e) => _financeTransactionFromJson(e),
  );
  final List<YearBackupInvoice> inv = _readList(
    m,
    'invoices',
    (Map<String, dynamic> e) => _invoiceFromJson(e),
  );
  return YearBackupSnapshot(
    schemaVersion: schemaVersion,
    year: year,
    accounts: accounts,
    creditCards: cards,
    financeTransactions: tx,
    invoices: inv,
  );
}

Map<String, dynamic> _accountToJson(YearBackupAccount e) {
  return <String, dynamic>{
    'id': e.id,
    'name': e.name,
    'type': e.type,
    'balanceInCents': e.balanceInCents,
  };
}

YearBackupAccount _accountFromJson(Map<String, dynamic> m) {
  return YearBackupAccount(
    id: _readInt(m, 'id'),
    name: _readString(m, 'name'),
    type: _readString(m, 'type'),
    balanceInCents: _readInt(m, 'balanceInCents'),
  );
}

Map<String, dynamic> _creditCardToJson(YearBackupCreditCard e) {
  return <String, dynamic>{
    'id': e.id,
    'name': e.name,
    'limitInCents': e.limitInCents,
    'closingDay': e.closingDay,
    'dueDay': e.dueDay,
  };
}

YearBackupCreditCard _creditCardFromJson(Map<String, dynamic> m) {
  return YearBackupCreditCard(
    id: _readInt(m, 'id'),
    name: _readString(m, 'name'),
    limitInCents: _readInt(m, 'limitInCents'),
    closingDay: _readInt(m, 'closingDay'),
    dueDay: _readInt(m, 'dueDay'),
  );
}

Map<String, dynamic> _financeTransactionToJson(YearBackupFinanceTransaction e) {
  return <String, dynamic>{
    'id': e.id,
    'amountInCents': e.amountInCents,
    'transactionType': e.transactionTypeStorage,
    'category': e.category,
    'description': e.description,
    'dateUtcMillis': e.dateUtcMillis,
    'paymentMethod': e.paymentMethodStorage,
    'accountId': e.accountId,
    'cardId': e.cardId,
    'installmentId': e.installmentId,
  };
}

YearBackupFinanceTransaction _financeTransactionFromJson(
  Map<String, dynamic> m,
) {
  return YearBackupFinanceTransaction(
    id: _readInt(m, 'id'),
    amountInCents: _readInt(m, 'amountInCents'),
    transactionTypeStorage: _readString(m, 'transactionType'),
    category: _readString(m, 'category'),
    description: _readString(m, 'description'),
    dateUtcMillis: _readInt(m, 'dateUtcMillis'),
    paymentMethodStorage: _readString(m, 'paymentMethod'),
    accountId: _readIntOpt(m, 'accountId'),
    cardId: _readIntOpt(m, 'cardId'),
    installmentId: _readIntOpt(m, 'installmentId'),
  );
}

Map<String, dynamic> _invoiceToJson(YearBackupInvoice e) {
  return <String, dynamic>{
    'id': e.id,
    'cardId': e.cardId,
    'month': e.month,
    'year': e.year,
    'totalInCents': e.totalInCents,
    'adjustedTotalInCents': e.adjustedTotalInCents,
    'isClosed': e.isClosed,
    'isPaid': e.isPaid,
  };
}

YearBackupInvoice _invoiceFromJson(Map<String, dynamic> m) {
  return YearBackupInvoice(
    id: _readInt(m, 'id'),
    cardId: _readInt(m, 'cardId'),
    month: _readInt(m, 'month'),
    year: _readInt(m, 'year'),
    totalInCents: _readInt(m, 'totalInCents'),
    adjustedTotalInCents: _readIntOpt(m, 'adjustedTotalInCents'),
    isClosed: _readBool(m, 'isClosed'),
    isPaid: _readBool(m, 'isPaid'),
  );
}

int _readInt(Map<String, dynamic> m, String key) {
  final Object? v = m[key];
  if (v is int) {
    return v;
  }
  if (v is num) {
    return v.toInt();
  }
  throw FormatException('Missing or invalid int field: $key');
}

int? _readIntOpt(Map<String, dynamic> m, String key) {
  final Object? v = m[key];
  if (v == null) {
    return null;
  }
  if (v is int) {
    return v;
  }
  if (v is num) {
    return v.toInt();
  }
  throw FormatException('Invalid optional int field: $key');
}

String _readString(Map<String, dynamic> m, String key) {
  final Object? v = m[key];
  if (v is String) {
    return v;
  }
  throw FormatException('Missing or invalid string field: $key');
}

bool _readBool(Map<String, dynamic> m, String key) {
  final Object? v = m[key];
  if (v is bool) {
    return v;
  }
  throw FormatException('Missing or invalid bool field: $key');
}

List<T> _readList<T>(
  Map<String, dynamic> m,
  String key,
  T Function(Map<String, dynamic> e) parse,
) {
  final Object? v = m[key];
  if (v is! List<dynamic>) {
    throw FormatException('Missing or invalid list field: $key');
  }
  return v.map<T>((dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      throw FormatException('List item for $key must be an object');
    }
    return parse(raw);
  }).toList();
}
