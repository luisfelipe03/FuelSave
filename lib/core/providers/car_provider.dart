import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fuelsave/core/enum/provider_state.dart';
import '../database/database_helper.dart';
import '../models/car_model.dart';

class CarProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<CarModel> _cars = [];
  ProviderState _state = ProviderState.Idle;
  String? _errorMessage;

  List<CarModel> get cars => List.unmodifiable(_cars);
  ProviderState get state => _state;
  String? get errorMessage => _errorMessage;

  CarProvider() {
    loadCars();
  }

  Future<void> loadCars() async {
    _setState(ProviderState.Loading);
    try {
      _cars = await _dbHelper.getCars();
      _cars.sort((a, b) => a.name.compareTo(b.name));
      _setState(ProviderState.Success);
    } catch (e, stackTrace) {
      _handleError("Erro ao carregar carros.", e, stackTrace);
    }
  }

  Future<bool> addCar(CarModel car) async {
    _setState(ProviderState.Loading);
    try {
      final id = await _dbHelper.insertCar(car);
      final newCar = car.copyWith(id: id);
      _cars.add(newCar);
      _cars.sort((a, b) => a.name.compareTo(b.name));
      _setState(ProviderState.Success);
      return true;
    } catch (e, stackTrace) {
      _handleError("Erro ao adicionar carro.", e, stackTrace);
      return false;
    }
  }

  Future<bool> updateCar(CarModel car) async {
    if (car.id == null) {
      _handleError("ID do carro é nulo para atualização.", null, null);
      return false;
    }

    _setState(ProviderState.Loading);
    try {
      final rows = await _dbHelper.updateCar(car);
      if (rows > 0) {
        final index = _cars.indexWhere((c) => c.id == car.id);
        if (index != -1) {
          _cars[index] = car;
          _cars.sort((a, b) => a.name.compareTo(b.name));
        } else {
          await loadCars(); // fallback
        }
        _setState(ProviderState.Success);
        return true;
      } else {
        _handleError("Carro com ID ${car.id} não encontrado para atualização.", null, null);
        return false;
      }
    } catch (e, stackTrace) {
      _handleError("Erro ao atualizar carro.", e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteCar(int id) async {
    _setState(ProviderState.Loading);
    try {
      final rows = await _dbHelper.deleteCar(id);
      if (rows > 0) {
        _cars.removeWhere((car) => car.id == id);
        _setState(ProviderState.Success);
        return true;
      } else {
        _handleError("Carro com ID $id não encontrado para deleção.", null, null);
        return false;
      }
    } catch (e, stackTrace) {
      _handleError("Erro ao deletar carro.", e, stackTrace);
      return false;
    }
  }

  Future<CarModel?> fetchCarById(int id) async {
    try {
      return await _dbHelper.getCarById(id);
    } catch (e, stackTrace) {
      print("Erro ao buscar carro por ID $id: $e\n$stackTrace");
      return null;
    }
  }

  void _setState(ProviderState newState) {
    _state = newState;
    if (newState != ProviderState.Error) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _handleError(String message, Object? error, StackTrace? stackTrace) {
    print("$message Error: $error\nStackTrace: $stackTrace");
    _errorMessage = message;
    _setState(ProviderState.Error);
  }
}
