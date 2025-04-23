// lib/modules/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:fuelsave/core/enum/provider_state.dart';
import 'package:fuelsave/core/models/car_model.dart';
import 'package:fuelsave/core/providers/car_provider.dart';
import 'package:fuelsave/modules/calculator/calculator_screen.dart';
import 'package:fuelsave/modules/car_management/add_edit_car_screen.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carProvider = context.watch<CarProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('FuelSave')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'calculate_fab',
        icon: const Icon(Icons.calculate),
        label: const Text('Calcular'),
        tooltip: 'Calcular Gasolina x Etanol',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CalculatorScreen()),
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Meus Veículos',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (carProvider.cars.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Adicionar'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddEditCarScreen(),
                          ),
                        );
                      },
                    ),
                  if (carProvider.cars.isEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.calculate_outlined, size: 18),
                      label: const Text('Calcular'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CalculatorScreen(),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Conteúdo principal
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => carProvider.loadCars(),
                child: _buildContent(context, carProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CarProvider carProvider) {
    if (carProvider.state == ProviderState.Error &&
        carProvider.errorMessage != null) {
      return _buildErrorView(context, carProvider.errorMessage!);
    }

    if (carProvider.state == ProviderState.Loading &&
        carProvider.cars.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (carProvider.cars.isEmpty &&
        carProvider.state != ProviderState.Loading) {
      return _buildEmptyView(context);
    }

    return _buildCarListView(context, carProvider.cars);
  }

  Widget _buildErrorView(BuildContext context, String errorMessage) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 64.0),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                "$errorMessage\n\nPuxe para baixo para tentar novamente.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 64.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.no_transfer_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum veículo cadastrado.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Toque no botão "+" no canto superior direito para adicionar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCarListView(BuildContext context, List<CarModel> cars) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80.0),
      itemCount: cars.length,
      itemBuilder: (context, index) {
        final car = cars[index];
        return _buildCarCard(context, car);
      },
    );
  }

  Widget _buildCarCard(BuildContext context, CarModel car) {
    final carProvider = context.read<CarProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_car,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_gas_station,
                          size: 14,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'G: ${car.gasConsumption.toStringAsFixed(1)} km/L',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.local_gas_station,
                          size: 14,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'E: ${car.ethanolConsumption.toStringAsFixed(1)} km/L',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Opções do Veículo',
                onSelected: (String result) async {
                  switch (result) {
                    case 'edit':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditCarScreen(carToEdit: car),
                        ),
                      );
                      break;
                    case 'delete':
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (BuildContext dialogContext) => AlertDialog(
                              title: const Text('Confirmar Exclusão'),
                              content: Text(
                                'Tem certeza que deseja excluir o veículo "${car.name}"? Seus históricos de abastecimento também serão perdidos.',
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Cancelar'),
                                  onPressed:
                                      () => Navigator.of(
                                        dialogContext,
                                      ).pop(false),
                                ),
                                TextButton(
                                  child: Text(
                                    'Excluir',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                  onPressed:
                                      () =>
                                          Navigator.of(dialogContext).pop(true),
                                ),
                              ],
                            ),
                      );

                      if (confirm == true &&
                          car.id != null &&
                          context.mounted) {
                        final success = await carProvider.deleteCar(car.id!);
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erro ao excluir ${car.name}: ${carProvider.errorMessage}',
                              ),
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Veículo ${car.name} excluído com sucesso!',
                              ),
                            ),
                          );
                        }
                      }
                      break;
                  }
                },
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Excluir'),
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
