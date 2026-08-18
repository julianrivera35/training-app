class ProgressEntry {
  final DateTime fecha;
  final double? peso;
  final int? dolorLumbar;    // 0-10
  final int? dolorHombro;
  final int? dolorRodilla;
  final double? velocidadLanzamiento; // km/h (opcional)
  final String notas;
  final Map<String, double> pesosReales; // ejercicio → kg usado

  ProgressEntry({
    required this.fecha,
    this.peso,
    this.dolorLumbar,
    this.dolorHombro,
    this.dolorRodilla,
    this.velocidadLanzamiento,
    this.notas = '',
    Map<String, double>? pesosReales,
  }) : pesosReales = pesosReales ?? {};

  Map<String, dynamic> toJson() => {
    'fecha': fecha.toIso8601String(),
    'peso': peso,
    'dolorLumbar': dolorLumbar,
    'dolorHombro': dolorHombro,
    'dolorRodilla': dolorRodilla,
    'velocidadLanzamiento': velocidadLanzamiento,
    'notas': notas,
    'pesosReales': pesosReales,
  };

  factory ProgressEntry.fromJson(Map<String, dynamic> j) => ProgressEntry(
    fecha: DateTime.parse(j['fecha']),
    peso: (j['peso'] as num?)?.toDouble(),
    dolorLumbar: j['dolorLumbar'] as int?,
    dolorHombro: j['dolorHombro'] as int?,
    dolorRodilla: j['dolorRodilla'] as int?,
    velocidadLanzamiento: (j['velocidadLanzamiento'] as num?)?.toDouble(),
    notas: j['notas'] ?? '',
    pesosReales: (j['pesosReales'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toDouble())),
  );
}
