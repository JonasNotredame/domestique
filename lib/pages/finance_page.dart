import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/finance.dart';
import '../services/finance_storage.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'EUR ');
  List<FinancialInstitution> _institutions = [];

  @override
  void initState() {
    super.initState();
    _institutions = FinanceStorage.loadInstitutions();
  }

  Future<void> _saveInstitutions() async {
    await FinanceStorage.saveInstitutions(_institutions);
  }

  double get _totalBalance {
    return _institutions.fold(0, (sum, institution) => sum + institution.totalBalance);
  }

  Map<AccountKind, double> get _totalsByAccountType {
    final result = <AccountKind, double>{};
    for (final institution in _institutions) {
      for (final account in institution.accounts) {
        result.update(
          account.kind,
          (value) => value + account.balance,
          ifAbsent: () => account.balance,
        );
      }
    }
    return result;
  }

  String _labelForInstitutionKind(InstitutionKind kind) {
    switch (kind) {
      case InstitutionKind.bank:
        return 'Bank';
      case InstitutionKind.broker:
        return 'Broker';
      case InstitutionKind.exchange:
        return 'Exchange';
      case InstitutionKind.pensionProvider:
        return 'Pension';
      case InstitutionKind.other:
        return 'Other';
    }
  }

  String _labelForAccountKind(AccountKind kind) {
    switch (kind) {
      case AccountKind.checking:
        return 'Checking';
      case AccountKind.savings:
        return 'Savings';
      case AccountKind.pension:
        return 'Pension';
      case AccountKind.investment:
        return 'Investment';
      case AccountKind.crypto:
        return 'Crypto';
      case AccountKind.cash:
        return 'Cash';
      case AccountKind.other:
        return 'Other';
    }
  }

  Color _colorForIndex(int index) {
    const colors = [
      Color(0xFF185ADB),
      Color(0xFF0A9396),
      Color(0xFFEE9B00),
      Color(0xFFAE2012),
      Color(0xFF6C757D),
      Color(0xFF4361EE),
    ];
    return colors[index % colors.length];
  }

  Future<void> _showInstitutionDialog() async {
    final nameController = TextEditingController();
    var selectedKind = InstitutionKind.bank;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: const Text('Add Institution'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<InstitutionKind>(
                    initialValue: selectedKind,
                    items: InstitutionKind.values
                        .map(
                          (kind) => DropdownMenuItem(
                            value: kind,
                            child: Text(_labelForInstitutionKind(kind)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setInnerState(() {
                          selectedKind = value;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    setState(() {
                      _institutions.add(
                        FinancialInstitution(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: name,
                          kind: selectedKind,
                          accounts: [],
                        ),
                      );
                    });
                    await _saveInstitutions();
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAccountDialog(int institutionIndex) async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    var selectedKind = AccountKind.savings;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: const Text('Add Account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Account Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AccountKind>(
                    initialValue: selectedKind,
                    items: AccountKind.values
                        .map(
                          (kind) => DropdownMenuItem(
                            value: kind,
                            child: Text(_labelForAccountKind(kind)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setInnerState(() {
                          selectedKind = value;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Account Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final balance = double.tryParse(balanceController.text.replaceAll(',', '.'));
                    if (name.isEmpty || balance == null) return;

                    final institution = _institutions[institutionIndex];
                    final updatedAccounts = [...institution.accounts];
                    updatedAccounts.add(
                      FinanceAccount(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: name,
                        kind: selectedKind,
                        balance: balance,
                      ),
                    );

                    setState(() {
                      _institutions[institutionIndex] = institution.copyWith(accounts: updatedAccounts);
                    });
                    await _saveInstitutions();
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditAmountDialog(int institutionIndex, int accountIndex) async {
    final institution = _institutions[institutionIndex];
    final account = institution.accounts[accountIndex];
    final balanceController = TextEditingController(text: account.balance.toStringAsFixed(2));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${account.name}'),
        content: TextField(
          controller: balanceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'New Amount',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final balance = double.tryParse(balanceController.text.replaceAll(',', '.'));
              if (balance == null) return;

              final updatedAccounts = [...institution.accounts];
              updatedAccounts[accountIndex] = account.copyWith(balance: balance);

              setState(() {
                _institutions[institutionIndex] = institution.copyWith(accounts: updatedAccounts);
              });
              await _saveInstitutions();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteInstitution(int institutionIndex) async {
    setState(() {
      _institutions.removeAt(institutionIndex);
    });
    await _saveInstitutions();
  }

  Future<void> _deleteAccount(int institutionIndex, int accountIndex) async {
    final institution = _institutions[institutionIndex];
    final updatedAccounts = [...institution.accounts]..removeAt(accountIndex);
    setState(() {
      _institutions[institutionIndex] = institution.copyWith(accounts: updatedAccounts);
    });
    await _saveInstitutions();
  }

  @override
  Widget build(BuildContext context) {
    final totalsByType = _totalsByAccountType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Situation'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInstitutionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Bank/Broker'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          if (_institutions.isEmpty)
            _buildEmptyState()
          else ...[
            _buildSectionTitle('Allocation by Account Type'),
            const SizedBox(height: 8),
            ...totalsByType.asMap().entries.map(
              (entry) => _buildAllocationRow(
                entry.key,
                _labelForAccountKind(entry.value.key),
                entry.value.value,
                _totalBalance,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Institutions & Accounts'),
            const SizedBox(height: 8),
            ..._institutions.asMap().entries.map(
              (entry) => _buildInstitutionCard(entry.key, entry.value),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF102542), Color(0xFF1C5D99)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Overview',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(_totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  '${_institutions.length}',
                  'Institutions',
                ),
              ),
              Expanded(
                child: _buildMetric(
                  '${_institutions.fold<int>(0, (sum, item) => sum + item.accounts.length)}',
                  'Accounts',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No financial accounts yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Add a bank, broker or pension provider to start tracking your totals.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAllocationRow(int index, String label, double amount, double total) {
    final percentage = total == 0 ? 0.0 : amount / total;
    final color = _colorForIndex(index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%  •  ${_currencyFormat.format(amount)}',
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 10,
              color: color,
              backgroundColor: color.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionCard(int institutionIndex, FinancialInstitution institution) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        institution.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _labelForInstitutionKind(institution.kind),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFormat.format(institution.totalBalance),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAccountDialog(institutionIndex),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Account'),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _deleteInstitution(institutionIndex),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (institution.accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'No accounts yet. Add your first account.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              )
            else ...[
              const SizedBox(height: 12),
              ...institution.accounts.asMap().entries.map(
                (entry) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(_labelForAccountKind(entry.value.kind)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _currencyFormat.format(entry.value.balance),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _showEditAmountDialog(institutionIndex, entry.key),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                              ),
                              IconButton(
                                onPressed: () => _deleteAccount(institutionIndex, entry.key),
                                icon: const Icon(Icons.delete_outline, size: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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
