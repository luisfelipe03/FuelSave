import 'package:intl/intl.dart';

enum FuelType {
  gasoline,
  ethanol;

  String get displayName {
    switch (this) {
      case FuelType.gasoline:
        return 'Gasolina';
      case FuelType.ethanol:
        return 'Etanol';
    }
  }
}

class RefuelRecordModel {
  final int? id;
  final int carId;
  final DateTime date;
  final FuelType fuelType;
  final double amountPaid;
  final double pricePerLiter;
  final double litersFilled;

  const RefuelRecordModel({
    this.id,
    required this.carId,
    required this.date,
    required this.fuelType,
    required this.amountPaid,
    required this.pricePerLiter,
  }) : litersFilled = (pricePerLiter > 0) ? amountPaid / pricePerLiter : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carId': carId,
      'date': date.toIso8601String(),
      'fuelType': fuelType.name,
      'amountPaid': amountPaid,
      'pricePerLiter': pricePerLiter,
    };
  }

  factory RefuelRecordModel.fromMap(Map<String, dynamic> map) {
    try {
      return RefuelRecordModel(
        id: _parseId(map['id']),
        carId: _parseCarId(map['carId']),
        date: _parseDate(map['date']),
        fuelType: _parseFuelType(map['fuelType']),
        amountPaid: _parsePositiveDouble(map['amountPaid'], 'amountPaid'),
        pricePerLiter: _parsePositiveDouble(map['pricePerLiter'], 'pricePerLiter'),
      );
    } catch (e, stackTrace) {
      throw FormatException(
        'Invalid refuel record data: ${e.toString()}\nStackTrace: $stackTrace',
      );
    }
  }

  RefuelRecordModel copyWith({
    int? id,
    int? carId,
    DateTime? date,
    FuelType? fuelType,
    double? amountPaid,
    double? pricePerLiter,
  }) {
    return RefuelRecordModel(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      date: date ?? this.date,
      fuelType: fuelType ?? this.fuelType,
      amountPaid: amountPaid ?? this.amountPaid,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
    );
  }

  double calculateCostPerKm(double carConsumptionKmPerLiter) {
    if (carConsumptionKmPerLiter <= 0) return double.infinity;
    if (pricePerLiter <= 0) return 0.0;
    return pricePerLiter / carConsumptionKmPerLiter;
  }

  String formattedDate() => DateFormat('dd/MM/yyyy').format(date);
  String formattedAmount() => _formatCurrency(amountPaid);
  String formattedPricePerLiter() => '${_formatCurrency(pricePerLiter)}/L';
  String formattedLitersFilled() => '${litersFilled.toStringAsFixed(2)}L';

  @override
  String toString() {
    return 'RefuelRecordModel('
        'id: $id, '
        'carId: $carId, '
        'date: ${formattedDate()}, '
        'fuelType: ${fuelType.displayName}, '
        'amount: ${formattedAmount()}, '
        'pricePerLiter: ${formattedPricePerLiter()}, '
        'liters: ${formattedLitersFilled()}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RefuelRecordModel &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            carId == other.carId &&
            date == other.date &&
            fuelType == other.fuelType &&
            amountPaid == other.amountPaid &&
            pricePerLiter == other.pricePerLiter);
  }

  @override
  int get hashCode =>
      Object.hash(id, carId, date, fuelType, amountPaid, pricePerLiter);

  static int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('Invalid ID: $value');
  }

  static int _parseCarId(dynamic value) {
    if (value is int && value > 0) return value;
    throw FormatException('Invalid carId: $value');
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      final date = DateTime.tryParse(value);
      if (date != null) return date;
    }
    throw FormatException('Invalid date format: $value');
  }

  static FuelType _parseFuelType(dynamic value) {
    if (value is String) {
      try {
        return FuelType.values.byName(value);
      } catch (_) {
        throw FormatException('Invalid fuel type string: $value');
      }
    }
    throw FormatException('Invalid fuel type data type: ${value.runtimeType}');
  }

  static double _parsePositiveDouble(dynamic value, String fieldName) {
    if (value is num) {
      final doubleValue = value.toDouble();
      if (doubleValue >= 0) return doubleValue;
    }
    throw FormatException('Invalid $fieldName (must be non-negative): $value');
  }

  static String _formatCurrency(double value) {
    final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);
    try {
      return format.format(value);
    } catch (_) {
      return 'R\$${value.toStringAsFixed(2).replaceAll('.', ',')}';
    }
  }
}
