import 'package:flutter/material.dart';
import 'package:farm/widgets/finance/transaction_list.dart';
import 'package:farm/widgets/finance/financial_summary.dart';
import 'package:farm/widgets/finance/add_transaction_button.dart';
import 'package:farm/widgets/finance/crop_financial_stats.dart';
import 'package:provider/provider.dart';
import 'package:farm/providers/finance_provider.dart';
import 'package:farm/widgets/finance/evolution_chart.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  _FinanceScreenState createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  @override
  void initState() {
    super.initState();
    _initFinanceData();
  }

  Future<void> _initFinanceData() async {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    await provider.initDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion Financière'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Aperçu'),
              Tab(text: 'Transactions'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  FinancialSummaryTab(),
                ],
              ),
            ),
            TransactionListTab(),
          ],
        ),
        floatingActionButton: const AddTransactionButton(),
      ),
    );
  }
}

class FinancialSummaryTab extends StatefulWidget {
  const FinancialSummaryTab({super.key});

  @override
  State<FinancialSummaryTab> createState() => _FinancialSummaryTabState();
}

class _FinancialSummaryTabState extends State<FinancialSummaryTab> {
  String _selectedPeriod = 'month';

  void _onPeriodChanged(String newPeriod) {
    setState(() {
      _selectedPeriod = newPeriod;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FinancialSummary(),
          const SizedBox(height: 24),
          EvolutionChart(
            transactionsFuture:
                provider.getTransactionsByPeriod(_selectedPeriod),
            title: 'Évolution Financière',
            selectedPeriod: _selectedPeriod,
            onPeriodChanged: _onPeriodChanged,
          ),
          const SizedBox(height: 24),
          Text(
            'Statistiques par Culture',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const CropFinancialStats(),
        ],
      ),
    );
  }
}

class TransactionListTab extends StatelessWidget {
  const TransactionListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const TransactionList();
  }
}
