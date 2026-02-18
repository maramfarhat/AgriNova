import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm/models/irrigation_config.dart';
import 'package:farm/providers/irrigation_provider.dart';
import 'package:farm/providers/crop_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:farm/widgets/irrigation/irrigation_schedule_picker.dart';
import 'package:farm/theme/app_theme.dart';

class IrrigationConfigScreen extends StatefulWidget {
  final IrrigationConfig? config;

  const IrrigationConfigScreen({super.key, this.config});

  @override
  State<IrrigationConfigScreen> createState() => _IrrigationConfigScreenState();
}

class _IrrigationConfigScreenState extends State<IrrigationConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _waterVolumeController = TextEditingController();
  final _durationController = TextEditingController();
  final _zoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isAutomatic = true;
  bool _isActive = true;
  String? _selectedCropId;
  IrrigationConfig? _config;

  @override
  void initState() {
    super.initState();
    // Valeurs par défaut
    _waterVolumeController.text = '0.0';
    _durationController.text = '30';
    _zoneController.text = 'Zone 1';
    _nameController.text = 'Nouvelle configuration';
    _isAutomatic = true;
    _isActive = true;

    // Si on modifie une configuration existante
    if (widget.config != null) {
      _waterVolumeController.text = widget.config!.waterVolume.toString();
      _durationController.text = widget.config!.duration.toString();
      _zoneController.text = widget.config!.zone;
      _isAutomatic = widget.config!.isAutomatic;
      _isActive = widget.config!.isActive;
      _selectedCropId = widget.config!.cropId;
      _nameController.text = widget.config!.name;
      _config = widget.config;
    }
  }

  void _updateConfigName(String cropName) {
    if (_nameController.text.isEmpty ||
        _nameController.text == 'Nouvelle configuration') {
      _nameController.text = 'Configuration pour $cropName';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.config == null
              ? 'Nouvelle configuration'
              : 'Modifier la configuration',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Consumer<CropProvider>(
              builder: (context, cropProvider, child) {
                final crops = cropProvider.crops;

                // Attendre que les cultures soient chargées
                if (crops.isEmpty) {
                  return const Center(
                    child: Text('Ajoutez d\'abord une culture'),
                  );
                }

                // S'assurer que _selectedCropId a une valeur valide
                if (_selectedCropId == null ||
                    !crops.any((crop) => crop.id == _selectedCropId)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedCropId = widget.config?.cropId ?? crops.first.id;
                      // Update name with first crop
                      if (_selectedCropId != null) {
                        final crop =
                            crops.firstWhere((c) => c.id == _selectedCropId);
                        _updateConfigName(crop.name);
                      }
                    });
                  });
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Culture',
                    filled: true,
                    fillColor: AppTheme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  value: _selectedCropId,
                  items: crops.map((crop) {
                    return DropdownMenuItem<String>(
                      value: crop.id,
                      child: Text(crop.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCropId = value;
                        // Update name when crop changes
                        final crop = crops.firstWhere((c) => c.id == value);
                        _updateConfigName(crop.name);
                      });
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            _buildTextField('Volume d\'eau (L)', _waterVolumeController),
            const SizedBox(height: 16),
            _buildTextField('Durée (minutes)', _durationController),
            const SizedBox(height: 16),
            _buildTextField('Zone d\'irrigation', _zoneController),
            const SizedBox(height: 16),
            IrrigationSchedulePicker(
              selectedDates: _config?.scheduledDates ?? [],
              onDatesChanged: (dates) {
                setState(() {
                  if (_config == null) {
                    _config = IrrigationConfig(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      cropId: _selectedCropId ?? '',
                      name: _nameController.text,
                      zone: _zoneController.text,
                      duration: int.parse(_durationController.text),
                      waterVolume: double.parse(_waterVolumeController.text),
                      isActive: _isActive,
                      isAutomatic: _isAutomatic,
                      scheduledDates: dates,
                      schedule: '',
                    );
                  } else {
                    _config = _config!.copyWith(
                      scheduledDates: dates,
                    );
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Mode automatique'),
              subtitle: const Text(
                  'Activer l\'irrigation automatique basée sur l\'humidité'),
              value: _isAutomatic,
              activeColor: Colors.green,
              activeTrackColor: AppTheme.beigeColor.withOpacity(0.5),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withOpacity(0.5),
              onChanged: (value) => setState(() => _isAutomatic = value),
            ),
            SwitchListTile(
              title: const Text('État actif'),
              subtitle: const Text('Activer/désactiver cette configuration'),
              value: _isActive,
              activeColor: Colors.green,
              activeTrackColor: AppTheme.beigeColor.withOpacity(0.5),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withOpacity(0.5),
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveConfig,
              child: Text(widget.config == null ? 'Ajouter' : 'Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppTheme.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ce champ est requis';
          }
          if (label.contains('Volume') || label.contains('Durée')) {
            if (double.tryParse(value) == null) {
              return 'Veuillez entrer un nombre valide';
            }
          }
          return null;
        },
      ),
    );
  }

  void _saveConfig() async {
    debugPrint('🔄 Début de la sauvegarde de la configuration');

    if (_formKey.currentState == null) {
      debugPrint('❌ _formKey.currentState est null');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Validation du formulaire échouée');
      return;
    }

    if (_selectedCropId == null) {
      debugPrint('❌ _selectedCropId est null');
      return;
    }

    try {
      debugPrint('✅ Formulaire validé, _selectedCropId: $_selectedCropId');

      // Vérifier que le nom n'est pas vide
      if (_nameController.text.isEmpty ||
          _nameController.text == 'Nouvelle configuration') {
        debugPrint('❌ Nom de configuration invalide: ${_nameController.text}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer un nom pour la configuration'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      debugPrint('📝 Création de la nouvelle configuration');
      debugPrint('  - Nom: ${_nameController.text}');
      debugPrint('  - Zone: ${_zoneController.text}');
      debugPrint('  - Durée: ${_durationController.text}');
      debugPrint('  - Volume: ${_waterVolumeController.text}');
      debugPrint('  - Culture ID: $_selectedCropId');

      final newConfig = IrrigationConfig(
        id: widget.config?.id ?? const Uuid().v4(),
        cropId: _selectedCropId ?? '',
        name: _nameController.text,
        zone: _zoneController.text,
        duration: int.parse(_durationController.text),
        waterVolume: double.parse(_waterVolumeController.text),
        isActive: _isActive,
        isAutomatic: _isAutomatic,
        scheduledDates: _config?.scheduledDates ?? [],
        schedule: _config?.schedule ?? '',
      );

      debugPrint('✅ Configuration créée avec ID: ${newConfig.id}');

      final provider = Provider.of<IrrigationProvider>(context, listen: false);
      debugPrint('✅ Provider récupéré');

      if (widget.config == null) {
        debugPrint('🔄 Ajout de la nouvelle configuration');
        await provider.addConfig(newConfig);
        debugPrint('✅ Configuration ajoutée avec succès: ${newConfig.id}');
      } else {
        debugPrint('🔄 Mise à jour de la configuration existante');
        final updatedConfig = newConfig.copyWith(
          scheduledDates:
              _config?.scheduledDates ?? widget.config!.scheduledDates,
        );
        debugPrint('Updating config with ID: ${updatedConfig.id}');
        await provider.updateConfig(updatedConfig);
        debugPrint('✅ Configuration mise à jour avec succès');
      }

      if (mounted) {
        debugPrint('🔄 Retour à l\'écran précédent');
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la sauvegarde: $e');
      debugPrint('❌ Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _waterVolumeController.dispose();
    _durationController.dispose();
    _zoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
