import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fuelsave/core/enum/provider_state.dart';
import 'package:fuelsave/core/models/car_model.dart';
import 'package:fuelsave/core/models/price_record_model.dart';
import 'package:fuelsave/core/providers/car_provider.dart';
import 'package:fuelsave/core/providers/history_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum BestFuelOption { gasoline, ethanol, indifferent }

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _gasPriceController = TextEditingController();
  final _ethanolPriceController = TextEditingController();

  CarModel? _selectedCar; 
  BestFuelOption? _calculationResult;
  double? _costPerKmGas;
  double? _costPerKmEthanol;
  bool _isLoading = false;

  // Formatador de moeda
  final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void dispose() {
    _gasPriceController.dispose();
    _ethanolPriceController.dispose();
    super.dispose();
  }

  void _calculateBestOption() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_selectedCar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um veículo.'))
      );
      return;
    }

    final gasPrice = double.parse(_gasPriceController.text.replaceAll(',', '.'));
    final ethanolPrice = double.parse(_ethanolPriceController.text.replaceAll(',', '.'));

    if (_selectedCar!.gasConsumption <= 0 || _selectedCar!.ethanolConsumption <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Os dados de consumo do veículo selecionado são inválidos.'))
      );
      setState(() {
         _calculationResult = null;
         _costPerKmGas = null;
         _costPerKmEthanol = null;
      });
      return;
    }

    final costGas = gasPrice / _selectedCar!.gasConsumption;
    final costEthanol = ethanolPrice / _selectedCar!.ethanolConsumption;

    setState(() {
      _costPerKmGas = costGas;
      _costPerKmEthanol = costEthanol;

      const indifferenceMargin = 0.01; // 1%
      if (costEthanol < costGas * (1.0 - indifferenceMargin)) {
        _calculationResult = BestFuelOption.ethanol;
      } else if (costGas < costEthanol * (1.0 - indifferenceMargin)) {
        _calculationResult = BestFuelOption.gasoline;
      } else {
        _calculationResult = BestFuelOption.indifferent; // Praticamente iguais
      }
    });
  }

  Future<void> _savePricesToHistory() async {
     final gasPriceText = _gasPriceController.text.replaceAll(',', '.');
     final ethanolPriceText = _ethanolPriceController.text.replaceAll(',', '.');
     final gasPrice = double.tryParse(gasPriceText);
     final ethanolPrice = double.tryParse(ethanolPriceText);

     if (gasPrice == null || ethanolPrice == null || gasPrice <= 0 || ethanolPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insira preços válidos para salvar no histórico.'))
        );
        return;
     }

     setState(() => _isLoading = true);
     final historyProvider = context.read<HistoryProvider>();

     final record = PriceRecordModel(
       date: DateTime.now(),
       gasolinePrice: gasPrice,
       ethanolPrice: ethanolPrice,
     );

     final success = await historyProvider.addPriceRecord(record);

     if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Preços salvos no histórico com sucesso!'))
           );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Erro ao salvar preços: ${historyProvider.errorMessage ?? 'Erro desconhecido'}'),
               backgroundColor: Theme.of(context).colorScheme.error,
             )
           );
        }
     }
  }


  @override
  Widget build(BuildContext context) {
    final carProvider = context.watch<CarProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora Flex'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCarSelector(context, carProvider),
              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildPriceInput(
                      controller: _gasPriceController,
                      labelText: 'Preço Gasolina (R\$/L)',
                      hintText: 'Ex: 5,99',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPriceInput(
                      controller: _ethanolPriceController,
                      labelText: 'Preço Etanol (R\$/L)',
                      hintText: 'Ex: 3,89',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Calcular Melhor Opção'),
                onPressed: carProvider.cars.isEmpty || _selectedCar == null || _selectedCar!.gasConsumption <= 0 || _selectedCar!.ethanolConsumption <= 0
                  ? null
                  : _calculateBestOption,
              ),
              const SizedBox(height: 24),

              if (_calculationResult != null)
                _buildResultCard(theme),

              const SizedBox(height: 16),

               if (_gasPriceController.text.isNotEmpty || _ethanolPriceController.text.isNotEmpty)
                OutlinedButton.icon(
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.history_edu_outlined),
                  label: Text(_isLoading ? 'Salvando...' : 'Salvar Preços no Histórico'),
                  onPressed: _isLoading ? null : _savePricesToHistory,
                  style: OutlinedButton.styleFrom(
                     side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarSelector(BuildContext context, CarProvider carProvider) {
    if (carProvider.state == ProviderState.Loading) {
      return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Carregando veículos...')));
    }
    if (carProvider.cars.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Nenhum veículo cadastrado.\nAdicione um veículo na tela inicial primeiro.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      );
    }

    return DropdownButtonFormField<CarModel>(
      value: _selectedCar, // Carro atualmente selecionado
      decoration: InputDecoration(
        labelText: 'Selecione o Veículo',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.directions_car),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      validator: (value) => value == null ? 'Selecione um veículo' : null,
      items: carProvider.cars.map((car) {
        return DropdownMenuItem<CarModel>(
          value: car,
          child: Text(
            car.name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (CarModel? newValue) {
        setState(() {
          _selectedCar = newValue;
          _calculationResult = null;
          _costPerKmGas = null;
          _costPerKmEthanol = null;
        });
      },
      hint: const Text('Escolha um veículo'),
      isExpanded: true, 
    );
  }

  Widget _buildPriceInput({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: const OutlineInputBorder(),
        prefixText: 'R\$ ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Informe o preço';
        }
        final price = double.tryParse(value.replaceAll(',', '.'));
        if (price == null || price <= 0) {
          return 'Preço inválido';
        }
        return null; // Válido
      },
      onChanged: (_) {
         if (_calculationResult != null) {
           setState(() => _calculationResult = null);
         }
      },
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    IconData icon;
    String title;
    Color color;

    switch (_calculationResult!) {
      case BestFuelOption.gasoline:
        icon = Icons.local_gas_station;
        title = 'Abasteça com Gasolina!';
        color = Colors.orangeAccent;
        break;
      case BestFuelOption.ethanol:
        icon = Icons.eco;
        title = 'Abasteça com Etanol!';
        color = Colors.green;
        break;
      case BestFuelOption.indifferent:
        icon = Icons.compare_arrows;
        title = 'Tanto faz!';
        color = Colors.blueGrey;
        break;
    }

    return Card(
      elevation: 4,
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_costPerKmGas != null && _costPerKmEthanol != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCostPerKmInfo(
                    label: 'Gasolina',
                    cost: _costPerKmGas!,
                    isBest: _calculationResult == BestFuelOption.gasoline || _calculationResult == BestFuelOption.indifferent,
                    theme: theme,
                  ),
                   _buildCostPerKmInfo(
                    label: 'Etanol',
                    cost: _costPerKmEthanol!,
                    isBest: _calculationResult == BestFuelOption.ethanol || _calculationResult == BestFuelOption.indifferent,
                    theme: theme,
                  ),
                ],
              ),
              if (_calculationResult == BestFuelOption.indifferent)
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0),
                   child: Text(
                     'A diferença de custo por Km é mínima.',
                     style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                     textAlign: TextAlign.center,
                   ),
                 ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostPerKmInfo({
    required String label,
    required double cost,
    required bool isBest,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isBest ? theme.colorScheme.onSurface : theme.colorScheme.outline,
          ),
        ),
        Text(
          '${_currencyFormatter.format(cost)} / Km',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
            color: isBest ? theme.colorScheme.onSurface : theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

