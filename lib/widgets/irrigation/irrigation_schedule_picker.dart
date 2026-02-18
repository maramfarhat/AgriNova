import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farm/theme/app_theme.dart';

class IrrigationSchedulePicker extends StatefulWidget {
  final List<DateTime> selectedDates;
  final Function(List<DateTime>) onDatesChanged;

  const IrrigationSchedulePicker({
    Key? key,
    required this.selectedDates,
    required this.onDatesChanged,
  }) : super(key: key);

  @override
  State<IrrigationSchedulePicker> createState() => _IrrigationSchedulePickerState();
}

class _IrrigationSchedulePickerState extends State<IrrigationSchedulePicker> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  late List<DateTime> _selectedDates;

  @override
  void initState() {
    super.initState();
    _selectedDates = List.from(widget.selectedDates);
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.darkBeigeColor,
              onPrimary: Colors.black87,
              surface: AppTheme.beigeColor,
              onSurface: Colors.black87,
              secondary: AppTheme.beigeColor,
              onSecondary: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black87,
              ),
            ),
            iconTheme: const IconThemeData(
              color: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppTheme.darkBeigeColor,
                onPrimary: Colors.black87,
                surface: AppTheme.beigeColor,
                onSurface: Colors.black87,
                secondary: AppTheme.beigeColor,
                onSecondary: Colors.black87,
              ),
              timePickerTheme: const TimePickerThemeData(
                dialHandColor: Colors.black87,
                hourMinuteTextColor: Colors.black87,
                dayPeriodTextColor: Colors.black87,
                dialTextColor: Colors.black87,
                entryModeIconColor: Colors.black87,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        final DateTime selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          _selectedDates = List.from(widget.selectedDates)..add(selectedDateTime);
          _selectedDates.sort();
          widget.onDatesChanged(_selectedDates);
        });
      }
    }
  }

  void _removeDateTime(DateTime date) {
    final List<DateTime> updatedDates = List.from(widget.selectedDates)
      ..remove(date);
    widget.onDatesChanged(updatedDates);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calendrier d\'irrigation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.selectedDates.length,
                itemBuilder: (context, index) {
                  final date = widget.selectedDates[index];
                  return ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(_dateFormat.format(date)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _selectedDates.removeAt(index);
                          widget.onDatesChanged(_selectedDates);
                        });
                      },
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: () => _selectDateTime(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une date'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}