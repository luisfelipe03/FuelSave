import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fuelsave/core/enum/provider_state.dart';
import 'package:fuelsave/core/models/car_model.dart';
import 'package:fuelsave/core/models/refuel_record_model.dart';
import 'package:fuelsave/core/providers/car_provider.dart';
import 'package:fuelsave/core/providers/history_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddRefuelScreen extends StatefulWidget {
  const AddRefuelScreen({super.key});

  @override
  State<AddRefuelScreen> createState() => _AddRefuelScreenState();
}

class _AddRefuelScreenState extends State<AddRefuelScreen> {
  final _formKey = GlobalKey<FormState>();

  // Estado do formulário
  CarModel? _selectedCar;
  FuelType _selectedFuelType = FuelType.gasoline; // Padrão para gasolina
  DateTime _selectedDate = DateTime.now(); // Padrão para data atual
  final _amountPaidController = TextEditingController();
  final _pricePerLiterController = TextEditingController();

  bool _isSaving = false;

  // Formatador de data
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    // Pré-seleciona o primeiro carro se houver apenas um
    final carProvider = context.read<CarProvider>();
    if (carProvider.cars.length == 1) {
      _selectedCar = carProvider.cars.first;
    }
  }


  @override
  void dispose() {
    _amountPaidController.dispose();
    _pricePerLiterController.dispose();
    super.dispose();
  }

  /// Mostra o DatePicker para selecionar a data
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000), // Limite inicial
      lastDate: DateTime.now(), // Não permite datas futuras
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Tenta salvar o registro de abastecimento
  Future<void> _saveRefuelRecord() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Não prossegue se inválido
    }
    if (_selectedCar == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Por favor, selecione um veículo.'))
       );
       return;
    }

    setState(() => _isSaving = true);

    // Obtém valores (já validados)
    final amountPaid = double.parse(_amountPaidController.text.replaceAll(',', '.'));
    final pricePerLiter = double.parse(_pricePerLiterController.text.replaceAll(',', '.'));

    // Cria o objeto RefuelRecordModel
    final record = RefuelRecordModel(
      carId: _selectedCar!.id!, // ID do carro selecionado (garantido não nulo pela validação)
      date: _selectedDate,
      fuelType: _selectedFuelType,
      amountPaid: amountPaid,
      pricePerLiter: pricePerLiter,
      // litersFilled é calculado automaticamente no modelo
    );

    // Chama o provider
    final historyProvider = context.read<HistoryProvider>();
    final success = await historyProvider.addRefuelRecord(record);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abastecimento registrado com sucesso!'))
        );
        Navigator.of(context).pop(); // Volta para a tela anterior
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar: ${historyProvider.errorMessage ?? 'Erro desconhecido'}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          )
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // Ouve o CarProvider para a lista de carros
    final carProvider = context.watch<CarProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Abastecimento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Seletor de Veículo ---
              _buildCarSelector(context, carProvider),
              const SizedBox(height: 16),

              // --- Seletor de Tipo de Combustível ---
              _buildFuelTypeSelector(theme),
              const SizedBox(height: 16),

              // --- Campos Valor Pago e Preço/Litro ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildNumericInput(
                      controller: _amountPaidController,
                      labelText: 'Valor Pago (R\$)',
                      prefixText: 'R\$ ',
                      validator: (value) {
                         if (value == null || value.trim().isEmpty) return 'Informe o valor';
                         final val = double.tryParse(value.replaceAll(',', '.'));
                         if (val == null || val <= 0) return 'Valor inválido';
                         return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                   Expanded(
                    child: _buildNumericInput(
                      controller: _pricePerLiterController,
                      labelText: 'Preço / Litro (R\$)',
                       prefixText: 'R\$ ',
                       validator: (value) {
                         if (value == null || value.trim().isEmpty) return 'Informe o preço/L';
                         final val = double.tryParse(value.replaceAll(',', '.'));
                         if (val == null || val <= 0) return 'Preço inválido';
                         return null;
                       },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Seletor de Data ---
              _buildDatePicker(context, theme),
              const SizedBox(height: 32),

              // --- Botão Salvar ---
              FilledButton.icon(
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Salvando...' : 'Salvar Registro'),
                onPressed: _isSaving ? null : _saveRefuelRecord,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets Auxiliares ---

  /// Constrói o Dropdown para selecionar o veículo
  Widget _buildCarSelector(BuildContext context, CarProvider carProvider) {
    if (carProvider.state == ProviderState.Loading) {
      return const Center(child: Text('Carregando veículos...'));
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
      value: _selectedCar,
      decoration: const InputDecoration(
        labelText: 'Veículo Abastecido',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.directions_car),
      ),
      validator: (value) => value == null ? 'Selecione um veículo' : null,
      items: carProvider.cars.map((car) {
        return DropdownMenuItem<CarModel>(
          value: car,
          child: Text(car.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (CarModel? newValue) {
        setState(() {
          _selectedCar = newValue;
        });
      },
      hint: const Text('Escolha um veículo'),
      isExpanded: true,
    );
  }

  /// Constrói o seletor de tipo de combustível (Segmented Button)
  Widget _buildFuelTypeSelector(ThemeData theme) {
    // Usando SegmentedButton para um visual moderno
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text('Tipo de Combustível', style: theme.textTheme.labelLarge),
         const SizedBox(height: 8),
         SegmentedButton<FuelType>(
          segments: const <ButtonSegment<FuelType>>[
            ButtonSegment<FuelType>(
                value: FuelType.gasoline,
                label: Text('Gasolina'),
                icon: Icon(Icons.local_gas_station)),
            ButtonSegment<FuelType>(
                value: FuelType.ethanol,
                label: Text('Etanol'),
                icon: Icon(Icons.eco)),
          ],
          selected: <FuelType>{_selectedFuelType}, // O estado atual
          onSelectionChanged: (Set<FuelType> newSelection) {
            setState(() {
              // Atualiza o estado com o novo tipo selecionado
              _selectedFuelType = newSelection.first;
            });
          },
           style: SegmentedButton.styleFrom(
             // Ajusta o estilo visual se necessário
             // visualDensity: VisualDensity.compact,
           ),
        ),
      ],
    );
  }

  /// Constrói um campo de input numérico
  Widget _buildNumericInput({
    required TextEditingController controller,
    required String labelText,
    required String prefixText,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        prefixText: prefixText,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,3}')), // Permite até 3 casas decimais para preço/L
      ],
      validator: validator,
    );
  }

  /// Constrói o seletor de data
  Widget _buildDatePicker(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data do Abastecimento', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        InkWell( // Torna a área clicável
          onTap: () => _selectDate(context),
          child: InputDecorator( // Simula a aparência de um campo de texto
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              _dateFormatter.format(_selectedDate), // Mostra a data formatada
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
      ],
    );
  }
}
