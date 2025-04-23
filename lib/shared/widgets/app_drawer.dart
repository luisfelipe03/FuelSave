import 'package:flutter/material.dart';
import 'package:fuelsave/modules/calculator/calculator_screen.dart';
import 'package:fuelsave/modules/history/price_history_screen.dart';
import 'package:fuelsave/modules/history/refuel_history_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(theme),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.directions_car_filled,
                  title: 'Meus Veículos',
                  onTap: () => _navigateTo(context, '/home'),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.calculate,
                  title: 'Calculadora Flex',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CalculatorScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.local_gas_station,
                  title: 'Abastecimentos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RefuelHistoryScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.timeline,
                  title: 'Histórico de Preços',
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
                    Navigator.push(
                      // Navega para PriceHistoryScreen
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PriceHistoryScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.info_outline,
                  title: 'Sobre',
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(ThemeData theme) {
    return DrawerHeader(
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car,
                size: 32,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Text(
                'FuelSave',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Menu Principal',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.8)),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      minLeadingWidth: 24,
      horizontalTitleGap: 4,
      onTap: onTap,
    );
  }

  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pop(context);
    Navigator.pushNamed(context, routeName);
  }

  void _showAboutDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sobre o FuelSave'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Versão: 1.0.0'),
                SizedBox(height: 8),
                Text(
                  'FuelSave é um aplicativo para gerenciamento de consumo de combustível.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }
}
