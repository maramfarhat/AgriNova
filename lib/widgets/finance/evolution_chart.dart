// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:farm/providers/finance_provider.dart';
import 'dart:math' show min, max, pow, log;
import 'package:intl/intl.dart';

class EvolutionChart extends StatefulWidget {
  final Future<List<TransactionData>> transactionsFuture;
  final String title;
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const EvolutionChart({
    Key? key,
    required this.transactionsFuture,
    required this.title,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  }) : super(key: key);

  @override
  State<EvolutionChart> createState() => _EvolutionChartState();
}

class _EvolutionChartState extends State<EvolutionChart> {
  List<FlSpot> incomeSpots = [];
  List<FlSpot> expenseSpots = [];
  double maxY = 0;
  final Color _incomeColor = const Color(0xFF2E7D32); // Vert pour les revenus
  final Color _expenseColor =
      const Color(0xFFD32F2F); // Rouge pour les dépenses

  @override
  void initState() {
    super.initState();
    _updateChartData();
  }

  @override
  void didUpdateWidget(EvolutionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod ||
        oldWidget.transactionsFuture != widget.transactionsFuture) {
      _updateChartData();
    }
  }

  Future<void> _updateChartData() async {
    try {
      final transactions = await widget.transactionsFuture;
      debugPrint(
          'Received ${transactions.length} transactions for period ${widget.selectedPeriod}');
      for (var t in transactions) {
        debugPrint('Transaction: date=${t.date}, amount=${t.amount}');
      }

      final newIncomeSpots = _generateSpots(transactions, true);
      final newExpenseSpots = _generateSpots(transactions, false);

      setState(() {
        incomeSpots = newIncomeSpots;
        expenseSpots = newExpenseSpots;
        maxY = _calculateMaxY();
      });
    } catch (e) {
      debugPrint('Error updating chart data: $e');
      setState(() {
        incomeSpots = [];
        expenseSpots = [];
        maxY = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Évolution Financière',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<String>(
                value: widget.selectedPeriod,
                items: const [
                  DropdownMenuItem(
                    value: 'minute',
                    child: Text('Minute'),
                  ),
                  DropdownMenuItem(
                    value: 'hour',
                    child: Text('Heure'),
                  ),
                  DropdownMenuItem(
                    value: 'day',
                    child: Text('Jour'),
                  ),
                  DropdownMenuItem(
                    value: 'week',
                    child: Text('Semaine'),
                  ),
                  DropdownMenuItem(
                    value: 'month',
                    child: Text('Mois'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    widget.onPeriodChanged(value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 100, // Intervalle de 100 DT
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < incomeSpots.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _formatDate(_getDateFromIndex(
                                  value.toInt(), _getSortedDates())),
                              style: const TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 100, // Intervalle de 100 DT
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()} DT',
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                minX: 0,
                maxX: incomeSpots.isNotEmpty ? incomeSpots.length - 1 : 0,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    color: _incomeColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: _incomeColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _incomeColor.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    color: _expenseColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: _expenseColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _expenseColor.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.white,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final textStyle = TextStyle(
                          color: touchedSpot.barIndex == 0
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        );
                        return LineTooltipItem(
                          touchedSpot.barIndex == 0
                              ? 'Revenu: ${touchedSpot.y.toStringAsFixed(2)} DT'
                              : 'Dépense: ${touchedSpot.y.toStringAsFixed(2)} DT',
                          textStyle,
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator:
                      (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: barData.color!,
                          strokeWidth: 2,
                        ),
                        FlDotData(
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: barData.color!,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _normalizeDate(DateTime date) {
    switch (widget.selectedPeriod) {
      case 'minute':
        return DateTime(
            date.year, date.month, date.day, date.hour, date.minute);
      case 'hour':
        return DateTime(date.year, date.month, date.day, date.hour);
      case 'day':
        return DateTime(date.year, date.month, date.day);
      case 'week':
        final firstDayOfWeek = date.subtract(Duration(days: date.weekday - 1));
        return DateTime(
            firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
      case 'month':
        return DateTime(date.year, date.month);
      default:
        return date;
    }
  }

  DateTime _getDateFromIndex(int index, List<DateTime> dates) {
    if (index >= 0 && index < dates.length) {
      return dates[index];
    }
    return DateTime.now();
  }

  Widget _getBottomTitle(DateTime date) {
    String text = switch (widget.selectedPeriod) {
      'minute' => DateFormat('HH:mm').format(date),
      'hour' => DateFormat('HH:00').format(date),
      'day' => DateFormat('dd/MM').format(date),
      'week' => 'S${DateFormat('w').format(date)}',
      'month' => _getMonthName(date.month),
      _ => '',
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  String _getPeriodLabel() {
    switch (widget.selectedPeriod) {
      case 'minute':
        return 'par minute';
      case 'hour':
        return 'par heure';
      case 'day':
        return 'par jour';
      case 'week':
        return 'par semaine';
      case 'month':
        return 'par mois';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    final months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return months[month - 1];
  }

  double _calculateOptimalInterval(double maxValue) {
    if (maxValue <= 0) return 1000;

    double magnitude = pow(10, (log(maxValue) / log(10)).floor()).toDouble();

    double interval = magnitude / 5;

    if (interval < 1000) {
      interval = 1000;
    } else if (interval < 5000)
      interval = 5000;
    else if (interval < 10000)
      interval = 10000;
    else
      interval = 20000;

    return interval;
  }

  String _formatNumber(int number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  String _formatDate(DateTime date) {
    switch (widget.selectedPeriod) {
      case 'day':
        return DateFormat('dd MMM').format(date);
      case 'week':
        return 'Semaine ${DateFormat('w').format(date)}';
      case 'month':
        return DateFormat('MMM yyyy').format(date);
      default:
        return DateFormat('dd/MM').format(date);
    }
  }

  double _calculateMaxY() {
    if (incomeSpots.isEmpty && expenseSpots.isEmpty) {
      return 200; // Valeur minimale par défaut augmentée
    }
    final maxIncome =
        incomeSpots.isEmpty ? 0 : incomeSpots.map((e) => e.y).reduce(max);
    final maxExpense =
        expenseSpots.isEmpty ? 0 : expenseSpots.map((e) => e.y).reduce(max);
    final maxValue = max(maxIncome, maxExpense);

    // Arrondir à la centaine supérieure
    return ((maxValue / 100).ceil() * 100 + 100).toDouble();
  }

  List<FlSpot> _generateSpots(
      List<TransactionData> transactions, bool isIncome) {
    if (transactions.isEmpty) return [];

    // Grouper les transactions par date
    Map<DateTime, double> groupedTransactions = {};

    // Initialiser toutes les dates avec 0
    for (var transaction in transactions) {
      groupedTransactions[_normalizeDate(transaction.date)] = 0;
    }

    // Remplir les données réelles
    for (var transaction in transactions) {
      final normalizedDate = _normalizeDate(transaction.date);
      if (isIncome && transaction.amount > 0) {
        groupedTransactions[normalizedDate] =
            (groupedTransactions[normalizedDate] ?? 0) + transaction.amount;
      } else if (!isIncome && transaction.amount < 0) {
        groupedTransactions[normalizedDate] =
            (groupedTransactions[normalizedDate] ?? 0) +
                transaction.amount.abs();
      }
    }

    // Trier les dates
    var sortedDates = groupedTransactions.keys.toList()..sort();
    var spots = <FlSpot>[];

    // Créer les points pour le graphique
    for (var i = 0; i < sortedDates.length; i++) {
      var date = sortedDates[i];
      var amount = groupedTransactions[date] ?? 0;
      spots.add(FlSpot(i.toDouble(), amount));
    }

    return spots;
  }

  List<DateTime> _getSortedDates() {
    Set<DateTime> allDates = {};

    // Collecter toutes les dates uniques
    for (var spot in incomeSpots) {
      allDates.add(
          _normalizeDate(DateTime.fromMillisecondsSinceEpoch(spot.x.toInt())));
    }
    for (var spot in expenseSpots) {
      allDates.add(
          _normalizeDate(DateTime.fromMillisecondsSinceEpoch(spot.x.toInt())));
    }

    var sortedDates = allDates.toList()..sort();
    return sortedDates;
  }
}
