class CarModel {
  final int? id;
  final String name;
  final double gasConsumption;
  final double ethanolConsumption;

  const CarModel({
    this.id,
    required this.name,
    required this.gasConsumption,
    required this.ethanolConsumption,
  });

  /// Converte o objeto para Map (usado para operações no banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gasConsumption': gasConsumption,
      'ethanolConsumption': ethanolConsumption,
    };
  }

  /// Converte um Map (do banco de dados) em um objeto CarModel
  /// 
  /// Lança [FormatException] se os dados forem inválidos
  factory CarModel.fromMap(Map<String, dynamic> map) {
    try {
      return CarModel(
        id: _parseId(map['id']),
        name: _parseName(map['name']),
        gasConsumption: _parseConsumption(map['gasConsumption']),
        ethanolConsumption: _parseConsumption(map['ethanolConsumption']),
      );
    } catch (e) {
      throw FormatException('Invalid car data: ${e.toString()}');
    }
  }

  /// Cria uma cópia do objeto com os campos atualizados
  CarModel copyWith({
    int? id,
    String? name,
    double? gasConsumption,
    double? ethanolConsumption,
  }) {
    return CarModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gasConsumption: gasConsumption ?? this.gasConsumption,
      ethanolConsumption: ethanolConsumption ?? this.ethanolConsumption,
    );
  }

  @override
  String toString() {
    return 'CarModel('
        'id: $id, '
        'name: "$name", '
        'gas: ${gasConsumption}Km/L, '
        'ethanol: ${ethanolConsumption}Km/L'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CarModel &&
        other.id == id &&
        other.name == name &&
        other.gasConsumption == gasConsumption &&
        other.ethanolConsumption == ethanolConsumption;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, gasConsumption, ethanolConsumption);
  }

  // Métodos auxiliares de parsing
  static int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('Invalid ID: $value');
  }

  static String _parseName(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Invalid name: $value');
  }

  static double _parseConsumption(dynamic value) {
    if (value is num) {
      final consumption = value.toDouble();
      if (consumption > 0) return consumption;
    }
    throw FormatException('Invalid consumption value: $value');
  }
}