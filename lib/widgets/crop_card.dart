import 'package:flutter/material.dart';
import 'package:farm/models/crop.dart';
import 'package:intl/intl.dart';
import 'package:farm/theme/app_theme.dart';

class CropCard extends StatelessWidget {
  final Crop crop;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CropCard({
    super.key,
    required this.crop,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    crop.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppTheme.primaryColor),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Modifier',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Supprimer',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            _InfoRow(
              icon: Icons.category,
              label: _getCropTypeLabel(crop.type),
            ),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Planté le: ${DateFormat('dd/MM/yyyy').format(crop.plantingDate)}',
            ),
            if (crop.harvestDate != null)
              _InfoRow(
                icon: Icons.event,
                label: 'Récolte prévue: ${DateFormat('dd/MM/yyyy').format(crop.harvestDate!)}',
              ),
            _InfoRow(
              icon: Icons.area_chart,
              label: '${crop.area} m²',
            ),
            _InfoRow(
              icon: Icons.flag,
              label: _getCropStatusLabel(crop.status),
              color: _getStatusColor(crop.status),
            ),
          ],
        ),
      ),
    );
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

  Color _getStatusColor(CropStatus status) {
    switch (status) {
      case CropStatus.sown:
        return Colors.orange;
      case CropStatus.growing:
        return Colors.lightGreen;
      case CropStatus.flowering:
        return Colors.purple;
      case CropStatus.fruiting:
        return Colors.amber;
      case CropStatus.harvested:
        return Colors.blue;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }
}