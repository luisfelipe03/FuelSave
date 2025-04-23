// lib/modules/car_management/add_edit_car_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para TextInputFormatters
import 'package:fuelsave/core/models/car_model.dart';
import 'package:fuelsave/core/providers/car_provider.dart';
import 'package:provider/provider.dart';

class AddEditCarScreen extends StatefulWidget {
  final CarModel? carToEdit;

  const AddEditCarScreen({super.key, this.carToEdit});

  @override
  State<AddEditCarScreen> createState() => _AddEditCarScreenState();
}

class _AddEditCarScreenState extends State<AddEditCarScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _gasConsumptionController;
  late TextEditingController _ethanolConsumptionController;

  bool _isSaving = false;

  bool get _isEditing => widget.carToEdit != null;

  @override
  void initState() {
    super.initState();
    final car = widget.carToEdit;
    _nameController = TextEditingController(text: car?.name ?? '');
    _gasConsumptionController = TextEditingController(
      text: car?.gasConsumption.toString() ?? '',
    );
    _ethanolConsumptionController = TextEditingController(
      text: car?.ethanolConsumption.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gasConsumptionController.dispose();
    _ethanolConsumptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCar() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);

      final name = _nameController.text.trim();
      final gasConsumption = double.tryParse(
          _gasConsumptionController.text.replaceAll(',', '.'));
      final ethanolConsumption = double.tryParse(
          _ethanolConsumptionController.text.replaceAll(',', '.'));

      if (gasConsumption == null || ethanolConsumption == null) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Valores de consumo inválidos. Use números e vírgula para decimais.'))
         );
         setState(() => _isSaving = false);
         return;
      }

      final car = CarModel(
        id: widget.carToEdit?.id,
        name: name,
        gasConsumption: gasConsumption,
        ethanolConsumption: ethanolConsumption,
      );

      final carProvider = context.read<CarProvider>();
      bool success;
      if (_isEditing) {
        success = await carProvider.updateCar(car);
      } else {
        success = await carProvider.addCar(car);
      }

      if (mounted) {
        setState(() => _isSaving = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Veículo ${_isEditing ? 'atualizado' : 'salvo'} com sucesso!'))
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: ${carProvider.errorMessage ?? 'Erro desconhecido'}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            )
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Veículo' : 'Adicionar Veículo'),
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome ou Apelido do Veículo',
                  hintText: 'Ex: Meu Carro, Onix 2023',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o nome do veículo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _gasConsumptionController,
                decoration: const InputDecoration(
                  labelText: 'Consumo Médio - Gasolina (Km/L)',
                  hintText: 'Ex: 12,5',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_gas_station),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
                ],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o consumo com gasolina.';
                  }
                  final val = double.tryParse(value.replaceAll(',', '.'));
                  if (val == null || val <= 0) {
                    return 'Valor inválido (deve ser maior que zero).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ethanolConsumptionController,
                decoration: const InputDecoration(
                  labelText: 'Consumo Médio - Etanol (Km/L)',
                  hintText: 'Ex: 8,7',
                  border: OutlineInputBorder(),
                   prefixIcon: Icon(Icons.local_gas_station), 
                ),
                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
                 inputFormatters: [
                   FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
                 ],
                 textInputAction: TextInputAction.done, 
                 validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o consumo com etanol.';
                  }
                   final val = double.tryParse(value.replaceAll(',', '.'));
                  if (val == null || val <= 0) {
                    return 'Valor inválido (deve ser maior que zero).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              FilledButton.icon(
                icon: _isSaving
                    ? SizedBox( 
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Salvando...' : 'Salvar Veículo'),
                onPressed: _isSaving ? null : _saveCar, 
              ),
            ],
          ),
        ),
      ),
    );
  }
}
