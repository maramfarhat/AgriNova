import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/models/crop.dart';
import 'package:farm/providers/crop_provider.dart';
import 'package:farm/theme/app_theme.dart';
import 'package:intl/intl.dart';

class CropFormScreen extends StatefulWidget {
  final dynamic crop;

  const CropFormScreen({super.key, this.crop});

  @override
  State<CropFormScreen> createState() => _CropFormScreenState();
}

class _CropFormScreenState extends State<CropFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late CropType _selectedType;
  late CropStatus _selectedStatus;
  late DateTime _plantingDate;
  DateTime? _harvestDate;
  late double _area;

  @override
  void initState() {
    super.initState();
    if (widget.crop != null) {
      final crop = widget.crop as Crop;
      _name = crop.name;
      _selectedType = crop.type;
      _selectedStatus = crop.status;
      _plantingDate = crop.plantingDate;
      _harvestDate = crop.harvestDate;
      _area = crop.area;
    } else {
      _name = '';
      _selectedType = CropType.vegetables;
      _selectedStatus = CropStatus.sown;
      _plantingDate = DateTime.now();
      _area = 0;
    }
  }

  String _getCropStatusLabel(CropStatus status) {
    switch (status) {
      case CropStatus.sown:
        return 'Semée';
      case CropStatus.growing:
        return 'En croissance';
      case CropStatus.flowering:
        return 'Floraison';
      case CropStatus.fruiting:
        return 'Fructification';
      case CropStatus.harvested:
        return 'Récoltée';
    }
  }

  String _getCropTypeLabel(CropType type) {
    switch (type) {
      case CropType.cereals:
        return 'Céréales';
      case CropType.vegetables:
        return 'Légumes';
      case CropType.fruits:
        return 'Fruits';
      case CropType.legumes:
        return 'Légumineuses';
      case CropType.other:
        return 'Autres';
    }
  }

  Future<void> _saveCrop() async {
    if (!_formKey.currentState!.validate()) return;

    final crop = Crop(
      id: widget.crop != null ? (widget.crop as Crop).id : null,
      name: _name,
      type: _selectedType,
      plantingDate: _plantingDate,
      harvestDate: _harvestDate,
      area: _area,
      status: _selectedStatus,
    );

    try {
      final cropProvider = Provider.of<CropProvider>(context, listen: false);
      if (widget.crop == null) {
        await cropProvider.addCrop(crop);
      } else {
        await cropProvider.updateCrop(crop);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.crop == null ? 'Ajouter une Culture' : 'Modifier la Culture'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(
                labelText: 'Nom de la culture',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _name = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CropType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type de culture',
                border: OutlineInputBorder(),
              ),
              items: CropType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getCropTypeLabel(type)),
                );
              }).toList(),
              onChanged: (CropType? value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date de plantation'),
              subtitle: Text(
                DateFormat('dd/MM/yyyy').format(_plantingDate),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                await _selectDate(context, true);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date de récolte (optionnel)'),
              subtitle: Text(
                _harvestDate != null
                    ? DateFormat('dd/MM/yyyy').format(_harvestDate!)
                    : 'Non définie',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                await _selectDate(context, false);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _area.toString(),
              decoration: const InputDecoration(
                labelText: 'Surface (m²)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une surface';
                }
                if (double.tryParse(value) == null) {
                  return 'Veuillez entrer un nombre valide';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _area = double.parse(value);
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CropStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'État de la culture',
                border: OutlineInputBorder(),
              ),
              items: CropStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_getCropStatusLabel(status)),
                );
              }).toList(),
              onChanged: (CropStatus? value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveCrop,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.crop == null ? 'Ajouter la culture' : 'Modifier la culture',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isPlantingDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPlantingDate ? _plantingDate : (_harvestDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.beigeColor,
              onPrimary: Colors.black87,
              surface: AppTheme.beigeColor,
              onSurface: Colors.black87,
              secondary: AppTheme.beigeColor,
              onSecondary: Colors.black87,
            ),
            dialogBackgroundColor: AppTheme.beigeColor,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black87,
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppTheme.beigeColor,
              headerBackgroundColor: AppTheme.beigeColor,
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFFD4BC94); // Darker beige for selection
                }
                return null;
              }),
              todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFFD4BC94);
                }
                return Colors.transparent;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.black87;
                }
                return Colors.black87;
              }),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.black87;
                }
                return Colors.black87;
              }),
              yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFFD4BC94);
                }
                return null;
              }),
              rangePickerShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Colors.black87, width: 1),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Colors.black87, width: 1),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isPlantingDate) {
          _plantingDate = picked;
        } else {
          _harvestDate = picked;
        }
      });
      _formKey.currentState?.validate();
    }
  }
}