enum InstitutionKind {
  bank,
  broker,
  exchange,
  pensionProvider,
  other,
}

enum AccountKind {
  checking,
  savings,
  pension,
  investment,
  crypto,
  cash,
  other,
}

class FinanceAccount {
  final String id;
  final String name;
  final AccountKind kind;
  final double balance;

  FinanceAccount({
    required this.id,
    required this.name,
    required this.kind,
    required this.balance,
  });

  FinanceAccount copyWith({
    String? id,
    String? name,
    AccountKind? kind,
    double? balance,
  }) {
    return FinanceAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      balance: balance ?? this.balance,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'kind': kind.name,
      'balance': balance,
    };
  }

  factory FinanceAccount.fromMap(Map<String, dynamic> map) {
    return FinanceAccount(
      id: map['id'] as String,
      name: map['name'] as String,
      kind: AccountKind.values.firstWhere(
        (item) => item.name == map['kind'],
        orElse: () => AccountKind.other,
      ),
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
    );
  }
}

class FinancialInstitution {
  final String id;
  final String name;
  final InstitutionKind kind;
  final List<FinanceAccount> accounts;

  FinancialInstitution({
    required this.id,
    required this.name,
    required this.kind,
    required this.accounts,
  });

  double get totalBalance {
    return accounts.fold(0, (sum, account) => sum + account.balance);
  }

  FinancialInstitution copyWith({
    String? id,
    String? name,
    InstitutionKind? kind,
    List<FinanceAccount>? accounts,
  }) {
    return FinancialInstitution(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      accounts: accounts ?? this.accounts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'kind': kind.name,
      'accounts': accounts.map((account) => account.toMap()).toList(),
    };
  }

  factory FinancialInstitution.fromMap(Map<String, dynamic> map) {
    return FinancialInstitution(
      id: map['id'] as String,
      name: map['name'] as String,
      kind: InstitutionKind.values.firstWhere(
        (item) => item.name == map['kind'],
        orElse: () => InstitutionKind.other,
      ),
      accounts: (map['accounts'] as List? ?? [])
          .map((entry) => FinanceAccount.fromMap(Map<String, dynamic>.from(entry as Map)))
          .toList(),
    );
  }
}
