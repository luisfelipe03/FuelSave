class PriceRecordModel {
  final int? id;
  final DateTime date;
  final double gasolinePrice; // Preço da gasolina (R$/L)
  final double ethanolPrice; // Preço do etanol (R$/L)
  final double priceRatio; // Razão preço etanol/gasolina (calculado)

  const PriceRecordModel({
    this.id,
    required this.date,
    required this.gasolinePrice,
    required this.ethanolPrice,
  }) : priceRatio = ethanolPrice / gasolinePrice;

  /// Converte o objeto para Map (usado para operações no banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'gasolinePrice': gasolinePrice,
      'ethanolPrice': ethanolPrice,
    };
  }

  /// Converte um Map (do banco de dados) em um objeto PriceRecordModel
  /// 
  /// Lança [FormatException] se os dados forem inválidos
  factory PriceRecordModel.fromMap(Map<String, dynamic> map) {
    try {
      return PriceRecordModel(
        id: _parseId(map['id']),
        date: _parseDate(map['date']),
        gasolinePrice: _parsePrice(map['gasolinePrice'], 'gasolinePrice'),
        ethanolPrice: _parsePrice(map['ethanolPrice'], 'ethanolPrice'),
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Invalid price record data: ${e.toString()}');
    }
  }

  /// Cria uma cópia do objeto com os campos atualizados
  PriceRecordModel copyWith({
    int? id,
    DateTime? date,
    double? gasolinePrice,
    double? ethanolPrice,
  }) {
    return PriceRecordModel(
      id: id ?? this.id,
      date: date ?? this.date,
      gasolinePrice: gasolinePrice ?? this.gasolinePrice,
      ethanolPrice: ethanolPrice ?? this.ethanolPrice,
    );
  }

  /// Formata a data para exibição (dd/MM/yyyy)
  String formattedDate() {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  /// Formata os preços para exibição (R$ X.XX)
  String formattedGasolinePrice() => _formatCurrency(gasolinePrice);
  String formattedEthanolPrice() => _formatCurrency(ethanolPrice);

  @override
  String toString() {
    return 'PriceRecordModel('
        'id: $id, '
        'date: ${formattedDate()}, '
        'gas: ${formattedGasolinePrice()}, '
        'ethanol: ${formattedEthanolPrice()}, '
        'ratio: ${priceRatio.toStringAsFixed(3)}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PriceRecordModel &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            date == other.date &&
            gasolinePrice == other.gasolinePrice &&
            ethanolPrice == other.ethanolPrice);
  }

  @override
  int get hashCode =>
      Object.hash(id, date, gasolinePrice, ethanolPrice);

  // --- Métodos Auxiliares Privados ---

  static int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('Invalid ID: $value');
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      final date = DateTime.tryParse(value);
      if (date != null) return date;
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    throw FormatException('Invalid date: $value');
  }

  static double _parsePrice(dynamic value, String fieldName) {
    if (value is num) {
      final price = value.toDouble();
      if (price >= 0) return price;
    }
    throw FormatException('Invalid $fieldName: $value');
  }

  static String _formatCurrency(double value) {
    return 'R\$${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}