// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/models/financial_transaction.dart';
import 'package:farm/providers/finance_provider.dart';
import 'package:intl/intl.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        final transactions = provider.transactions;

        if (transactions.isEmpty) {
          return const Center(
            child: Text('Aucune transaction'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return Dismissible(
              key: Key(transaction.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: const Color(0xFFE8DCC4), // Beige clair
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      title: const Text(
                        'Confirmer la suppression',
                        style: TextStyle(
                          color: Color(0xFF2E7D32), // Vert
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text(
                        'Voulez-vous vraiment supprimer cette transaction ?',
                        style: TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32), // Vert
                          ),
                          child: const Text(
                            'Annuler',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32), // Vert
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Supprimer',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              onDismissed: (direction) {
                provider.deleteTransaction(transaction.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Transaction supprimée'),
                    action: SnackBarAction(
                      label: 'Annuler',
                      onPressed: () {
                        // TODO: Implémenter la restauration de la transaction
                      },
                    ),
                  ),
                );
              },
              child: TransactionCard(transaction: transaction),
            );
          },
        );
      },
    );
  }
}

class TransactionCard extends StatelessWidget {
  final FinancialTransaction transaction;

  const TransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;
    final sign = isIncome ? '+' : '-';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            _getCategoryIcon(transaction.category),
            color: color,
          ),
        ),
        title: Text(transaction.description),
        subtitle: Text(
          DateFormat('dd MMMM yyyy', 'fr_FR').format(transaction.date),
        ),
        trailing: Text(
          '$sign${transaction.amount.toStringAsFixed(2)} DT',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.irrigation:
        return Icons.water_drop;
      case TransactionCategory.fertilizer:
        return Icons.grass;
      case TransactionCategory.pesticide:
        return Icons.bug_report;
      case TransactionCategory.sales:
        return Icons.attach_money;
      case TransactionCategory.other:
        return Icons.more_horiz;
    }
  }
}
