// lib/modules/history/refuel_history_screen.dart
import 'package:flutter/material.dart';
import 'package:fuelsave/core/enum/provider_state.dart';
import 'package:fuelsave/core/models/car_model.dart';
import 'package:fuelsave/core/models/refuel_record_model.dart';
import 'package:fuelsave/core/providers/car_provider.dart';
import 'package:fuelsave/core/providers/history_provider.dart';
import 'package:fuelsave/modules/history/add_refuel_screen.dart';
import 'package:provider/provider.dart';

class RefuelHistoryScreen extends StatefulWidget {
  const RefuelHistoryScreen({super.key});

  @override
  State<RefuelHistoryScreen> createState() => _RefuelHistoryScreenState();
}

class _RefuelHistoryScreenState extends State<RefuelHistoryScreen> {
  CarModel? _selectedCarFilter;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final historyProvider = context.read<HistoryProvider>();
    final carProvider = context.read<CarProvider>();

    if (historyProvider.state == ProviderState.Idle) {
      await historyProvider.loadHistories();
    }

    if (carProvider.state != ProviderState.Success &&
        carProvider.state != ProviderState.Loading) {
      await carProvider.loadCars();
    }
  }

  Future<void> _refreshHistory() async {
    await context.read<HistoryProvider>().loadHistories(
      carId: _selectedCarFilter?.id,
    );
  }

  Future<void> _confirmAndDeleteRecord(RefuelRecordModel record) async {
    final historyProvider = context.read<HistoryProvider>();
    final carProvider = context.read<CarProvider>();

    final car = carProvider.cars.firstWhere(
      (car) => car.id == record.carId,
      orElse:
          () => CarModel(
            id: -1,
            name: 'Desconhecido',
            gasConsumption: 0,
            ethanolConsumption: 0,
          ),
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: Text(
              'Tem certeza que deseja excluir este abastecimento de '
              '${record.fuelType.displayName} para o veículo "${car.name}" '
              'em ${record.formattedDate()}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Excluir',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );

    if (confirm == true && record.id != null && context.mounted) {
      final success = await historyProvider.deleteRefuelRecord(record.id!);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Registro de abastecimento excluído.'
                : 'Erro ao excluir registro: ${historyProvider.errorMessage ?? 'Erro desconhecido'}',
          ),
          backgroundColor: success ? null : Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyProvider = context.watch<HistoryProvider>();
    final carProvider = context.watch<CarProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Abastecimentos'),
        actions: [
          if (_selectedCarFilter != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined),
              tooltip: 'Limpar filtro',
              onPressed: () {
                setState(() => _selectedCarFilter = null);
                _refreshHistory();
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
            ),
          IconButton(
            icon: Icon(
              Icons.filter_alt_outlined,
              color:
                  _selectedCarFilter != null ? theme.colorScheme.primary : null,
            ),
            tooltip: 'Filtrar por veículo',
            onPressed:
                carProvider.cars.isEmpty ||
                        historyProvider.state == ProviderState.Loading
                    ? null
                    : () => _showCarFilterDialog(context, carProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_refuel',
        tooltip: 'Adicionar abastecimento',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRefuelScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: _buildContent(historyProvider, carProvider, theme),
    );
  }

  Widget _buildContent(
    HistoryProvider historyProvider,
    CarProvider carProvider,
    ThemeData theme,
  ) {
    if (historyProvider.state == ProviderState.Error &&
        historyProvider.errorMessage != null) {
      return _buildErrorView(historyProvider.errorMessage!, theme);
    }

    if (historyProvider.state == ProviderState.Loading &&
        historyProvider.refuelHistory.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (historyProvider.refuelHistory.isEmpty &&
        historyProvider.state != ProviderState.Loading) {
      return _buildEmptyView(theme);
    }

    return RefreshIndicator(
      onRefresh: _refreshHistory,
      child: _buildHistoryList(historyProvider, carProvider, theme),
    );
  }

  Widget _buildErrorView(String errorMessage, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar histórico:\n$errorMessage',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _refreshHistory,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_gas_station, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _selectedCarFilter == null
                  ? 'Nenhum abastecimento registrado.\nToque no "+" para adicionar.'
                  : 'Nenhum abastecimento registrado\npara "${_selectedCarFilter!.name}".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    HistoryProvider historyProvider,
    CarProvider carProvider,
    ThemeData theme,
  ) {
    final records = historyProvider.refuelHistory;
    final cars = carProvider.cars;

    if (_selectedCarFilter != null) {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: records.length,
        itemBuilder:
            (context, index) => _buildRecordCard(
              context,
              records[index],
              cars,
              showCarName: false,
            ),
      );
    }

    final groupedHistory = _groupHistoryByCar(records, cars);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: groupedHistory.length,
      itemBuilder: (context, index) {
        final carId = groupedHistory.keys.elementAt(index);
        final recordsForCar = groupedHistory[carId]!;
        final car = cars.firstWhere(
          (c) => c.id == carId,
          orElse:
              () => CarModel(
                id: -1,
                name: 'Veículo Desconhecido',
                gasConsumption: 0,
                ethanolConsumption: 0,
              ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                car.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            ...recordsForCar.map(
              (record) =>
                  _buildRecordCard(context, record, cars, showCarName: false),
            ),
            if (index < groupedHistory.length - 1)
              const Divider(height: 16, thickness: 1),
          ],
        );
      },
    );
  }

  Map<int, List<RefuelRecordModel>> _groupHistoryByCar(
    List<RefuelRecordModel> history,
    List<CarModel> cars,
  ) {
    final grouped = <int, List<RefuelRecordModel>>{};

    for (final record in history) {
      grouped.putIfAbsent(record.carId, () => []).add(record);
    }

    // Ordena pela data mais recente primeiro
    for (final records in grouped.values) {
      records.sort((a, b) => b.date.compareTo(a.date));
    }

    // Ordena os carros pela ordem na lista principal
    final orderedGrouped = <int, List<RefuelRecordModel>>{};
    for (final car in cars) {
      if (grouped.containsKey(car.id)) {
        orderedGrouped[car.id!] = grouped[car.id]!;
      }
    }

    return orderedGrouped;
  }

  Widget _buildRecordCard(
    BuildContext context,
    RefuelRecordModel record,
    List<CarModel> cars, {
    bool showCarName = true,
  }) {
    final theme = Theme.of(context);
    final car = cars.firstWhere(
      (c) => c.id == record.carId,
      orElse:
          () => CarModel(
            id: -1,
            name: 'Desconhecido',
            gasConsumption: 0,
            ethanolConsumption: 0,
          ),
    );

    final consumption =
        record.fuelType == FuelType.gasoline
            ? car.gasConsumption
            : car.ethanolConsumption;

    final costPerKm =
        consumption > 0 ? record.calculateCostPerKm(consumption) : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRecordDetails(context, record, car, costPerKm),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCarName)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    car.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          record.fuelType == FuelType.ethanol
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      record.fuelType == FuelType.ethanol
                          ? Icons.eco
                          : Icons.local_gas_station,
                      color:
                          record.fuelType == FuelType.ethanol
                              ? Colors.green
                              : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${record.formattedAmount()} • ${record.formattedLitersFilled()}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${record.fuelType.displayName} a ${record.formattedPricePerLiter()}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmAndDeleteRecord(record),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 52, top: 8),
                child: Row(
                  children: [
                    Text(
                      record.formattedDate(),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (costPerKm != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        'R\$ ${costPerKm.toStringAsFixed(3)}/km',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCarFilterDialog(
    BuildContext context,
    CarProvider carProvider,
  ) async {
    final selected = await showDialog<CarModel?>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filtrar por Veículo'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      carProvider.cars.map((car) {
                        return RadioListTile<CarModel>(
                          title: Text(car.name),
                          value: car,
                          groupValue: _selectedCarFilter,
                          onChanged: (value) => Navigator.pop(context, value),
                        );
                      }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Limpar Filtro'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, _selectedCarFilter),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );

    if (selected != _selectedCarFilter && mounted) {
      setState(() => _selectedCarFilter = selected);
      _refreshHistory();
    }
  }

  Future<void> _showRecordDetails(
    BuildContext context,
    RefuelRecordModel record,
    CarModel car,
    double? costPerKm,
  ) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Detalhes do Abastecimento'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      record.fuelType == FuelType.ethanol
                          ? Icons.eco
                          : Icons.local_gas_station,
                      color:
                          record.fuelType == FuelType.ethanol
                              ? Colors.green
                              : Colors.orange,
                    ),
                    title: Text(car.name),
                    subtitle: Text(record.formattedDate()),
                  ),
                  const Divider(),
                  _buildDetailItem('Veículo', car.name),
                  _buildDetailItem(
                    'Tipo de Combustível',
                    record.fuelType.displayName,
                  ),
                  _buildDetailItem('Data', record.formattedDate()),
                  _buildDetailItem(
                    'Preço por Litro',
                    record.formattedPricePerLiter(),
                  ),
                  _buildDetailItem(
                    'Litros Abastecidos',
                    record.formattedLitersFilled(),
                  ),
                  _buildDetailItem('Valor Total', record.formattedAmount()),
                  if (costPerKm != null)
                    _buildDetailItem(
                      'Custo por Km',
                      'R\$ ${costPerKm.toStringAsFixed(3)}',
                    ),
                ],
              ),
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}
