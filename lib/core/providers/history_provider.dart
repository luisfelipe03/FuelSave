import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fuelsave/core/enum/provider_state.dart';
import '../database/database_helper.dart';
import '../models/price_record_model.dart';
import '../models/refuel_record_model.dart';

class HistoryProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<PriceRecordModel> _priceHistory = [];
  List<RefuelRecordModel> _refuelHistory = [];
  ProviderState _state = ProviderState.Idle;
  String? _errorMessage;

  List<PriceRecordModel> get priceHistory => List.unmodifiable(_priceHistory);
  List<RefuelRecordModel> get refuelHistory => List.unmodifiable(_refuelHistory);
  ProviderState get state => _state;
  String? get errorMessage => _errorMessage;

  Future<void> loadHistories({int? carId, int? priceLimit, int? refuelLimit}) async {
    _setState(ProviderState.Loading);
    try {
      final results = await Future.wait([
        _dbHelper.getPriceHistory(limit: priceLimit),
        _dbHelper.getRefuelHistory(carId: carId, limit: refuelLimit),
      ]);

      _priceHistory = results[0] as List<PriceRecordModel>;
      _refuelHistory = results[1] as List<RefuelRecordModel>;

      _setState(ProviderState.Success);
    } catch (e, stackTrace) {
      _handleError("Erro ao carregar históricos.", e, stackTrace);
      _priceHistory = [];
      _refuelHistory = [];
    }
  }

  Future<bool> addPriceRecord(PriceRecordModel record) async {
    _setState(ProviderState.Loading);
    try {
      final id = await _dbHelper.insertPriceRecord(record);
      final newRecordWithId = record.copyWith(id: id);
      _priceHistory.insert(0, newRecordWithId);
      _setState(ProviderState.Success);
      return true;
    } catch (e, stackTrace) {
      _handleError("Erro ao adicionar registro de preço.", e, stackTrace);
      return false;
    }
  }

  Future<bool> deletePriceRecord(int id) async {
    _setState(ProviderState.Loading);
    try {
      final rowsAffected = await _dbHelper.deletePriceRecord(id);
      if (rowsAffected > 0) {
        _priceHistory.removeWhere((record) => record.id == id);
        _setState(ProviderState.Success);
        return true;
      }
      _handleError("Registro de preço com ID $id não encontrado para deleção.", null, null);
      return false;
    } catch (e, stackTrace) {
      _handleError("Erro ao deletar registro de preço.", e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteAllPriceHistory() async {
    _setState(ProviderState.Loading);
    try {
      final rowsAffected = await _dbHelper.deleteAllPriceHistory();
      if (rowsAffected >= 0) {
        _priceHistory = [];
        _setState(ProviderState.Success);
        return true;
      }
      _handleError("Erro inesperado ao deletar todo histórico de preços.", null, null);
      return false;
    } catch (e, stackTrace) {
      _handleError("Erro ao deletar todo histórico de preços.", e, stackTrace);
      return false;
    }
  }

  Future<bool> addRefuelRecord(RefuelRecordModel record) async {
    _setState(ProviderState.Loading);
    try {
      final id = await _dbHelper.insertRefuelRecord(record);
      final newRecordWithId = record.copyWith(id: id);
      _refuelHistory.insert(0, newRecordWithId);
      _setState(ProviderState.Success);
      return true;
    } catch (e, stackTrace) {
      _handleError("Erro ao adicionar registro de abastecimento.", e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteRefuelRecord(int id) async {
    _setState(ProviderState.Loading);
    try {
      final rowsAffected = await _dbHelper.deleteRefuelRecord(id);
      if (rowsAffected > 0) {
        _refuelHistory.removeWhere((record) => record.id == id);
        _setState(ProviderState.Success);
        return true;
      }
      _handleError("Registro de abastecimento com ID $id não encontrado para deleção.", null, null);
      return false;
    } catch (e, stackTrace) {
      _handleError("Erro ao deletar registro de abastecimento.", e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteAllRefuelHistory({int? carId}) async {
    _setState(ProviderState.Loading);
    try {
      final rowsAffected = await _dbHelper.deleteAllRefuelHistory(carId: carId);
      if (rowsAffected >= 0) {
        if (carId != null) {
          _refuelHistory.removeWhere((record) => record.carId == carId);
        } else {
          _refuelHistory = [];
        }
        _setState(ProviderState.Success);
        return true;
      }
      _handleError("Erro inesperado ao deletar histórico de abastecimento.", null, null);
      return false;
    } catch (e, stackTrace) {
      _handleError("Erro ao deletar histórico de abastecimento.", e, stackTrace);
      return false;
    }
  }

  void _setState(ProviderState newState) {
    _state = newState;
    if (newState != ProviderState.Error) _errorMessage = null;
    notifyListeners();
  }

  void _handleError(String message, Object? error, StackTrace? stackTrace) {
    print("$message Error: $error\nStackTrace: $stackTrace");
    _errorMessage = message;
    _setState(ProviderState.Error);
  }
}
