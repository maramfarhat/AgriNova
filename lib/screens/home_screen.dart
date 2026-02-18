import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Cultures',
        'icon': Icons.grass,
        'route': '/crops',
      },
      {
        'title': 'Irrigation',
        'icon': Icons.water_drop,
        'route': '/irrigation',
      },
      {
        'title': 'IoT',
        'icon': Icons.wifi_tethering,
        'route': '/iot',
      },
      {
        'title': 'Météo',
        'icon': Icons.wb_sunny,
        'route': '/weather',
      },
      {
        'title': 'Finances',
        'icon': Icons.account_balance_wallet,
        'route': '/finance',
      },
      {
        'title': 'Marché',
        'icon': Icons.shopping_cart,
        'route': '/market',
      },
      {
        'title': 'Robot Agricole',
        'icon': Icons.smart_toy,
        'route': '/robot',
      },
      {
        'title': 'AgriBot',
        'icon': Icons.chat,
        'route': '/agribot',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Management'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: menuItems.map((item) => _buildMenuCard(
          context,
          icon: item['icon'],
          title: item['title'],
          route: item['route'],
        )).toList(),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFBF5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}