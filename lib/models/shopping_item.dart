class ShoppingItem {
  final String categoria;   // "🧪 SUPLEMENTOS"
  final String nombre;
  final String cantidad;
  final String frecuencia;
  final String notas;
  bool comprado;

  ShoppingItem({
    required this.categoria,
    required this.nombre,
    this.cantidad = '',
    this.frecuencia = '',
    this.notas = '',
    this.comprado = false,
  });

  Map<String, dynamic> toJson() => {
    'categoria': categoria,
    'nombre': nombre,
    'cantidad': cantidad,
    'frecuencia': frecuencia,
    'notas': notas,
    'comprado': comprado,
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> j) => ShoppingItem(
    categoria: j['categoria'] ?? '',
    nombre: j['nombre'] ?? '',
    cantidad: j['cantidad'] ?? '',
    frecuencia: j['frecuencia'] ?? '',
    notas: j['notas'] ?? '',
    comprado: j['comprado'] ?? false,
  );
}
