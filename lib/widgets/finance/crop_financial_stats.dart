import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:farm/providers/finance_provider.dart';
import 'package:farm/providers/crop_provider.dart';
import 'package:farm/models/financial_transaction.dart';

class CropFinancialStats extends StatelessWidget {
  const CropFinancialStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FinanceProvider, CropProvider>(
      builder: (context, financeProvider, cropProvider, child) {
        final crops = cropProvider.crops;
        if (crops.isEmpty) {
          return const Center(
            child: Text('Aucune culture'),
          );
        }

        // Calculer les statistiques par culture
        final stats = <String, double>{};
        double total = 0;

        for (final crop in crops) {
          final transactions = financeProvider.getTransactionsForCrop(crop.id);
          double balance = 0;
          
          for (final transaction in transactions) {
            if (transaction.type == TransactionType.income) {
              balance += transaction.amount;
            } else {
              balance -= transaction.amount;
            }
          }
          
          stats[crop.name] = balance;
          total += balance.abs();
        }

        // Créer les sections du PieChart
        final sections = stats.entries.map((entry) {
          final color = entry.value >= 0 ? Colors.green : Colors.red;
          return PieChartSectionData(
            value: entry.value.abs(),
            title: '${entry.key}\n${entry.value.toStringAsFixed(2)} DT',
            color: color.withOpacity(0.8),
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

        return Column(
          children: [
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                  startDegreeOffset: -90,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Liste détaillée des statistiques
            ...stats.entries.map((entry) {
              final isProfit = entry.value >= 0;
              return ListTile(
                leading: Icon(
                  isProfit ? Icons.trending_up : Icons.trending_down,
                  color: isProfit ? Colors.green : Colors.red,
                ),
                title: Text(entry.key),
                trailing: Text(
                  '${entry.value.toStringAsFixed(2)} DT',
                  style: TextStyle(
                    color: isProfit ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

Color _getColorForCrop(String cropName) {
  // Générer une couleur unique basée sur le nom de la culture
  final hash = cropName.hashCode;
  return Colors.primaries[hash % Colors.primaries.length];
}