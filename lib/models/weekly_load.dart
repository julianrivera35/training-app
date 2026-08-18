class WeeklyLoad {
  final String grupo;
  final String nombre;
  final String dia;
  final double orm;
  final String unidad;
  final List<double> planKg;   // 8 semanas
  final List<double?> realKg;  // usuario llena

  WeeklyLoad({
    required this.grupo,
    required this.nombre,
    required this.dia,
    required this.orm,
    required this.unidad,
    required this.planKg,
    List<double?>? realKg,
  }) : realKg = realKg ?? List.filled(8, null);

  double? planForWeek(int week) =>
      (week >= 1 && week <= planKg.length) ? planKg[week - 1] : null;

  double? realForWeek(int week) =>
      (week >= 1 && week <= realKg.length) ? realKg[week - 1] : null;

  WeeklyLoad copyWithReal(int week, double? value) {
    final updated = List<double?>.from(realKg);
    if (week >= 1 && week <= updated.length) updated[week - 1] = value;
    return WeeklyLoad(
      grupo: grupo, nombre: nombre, dia: dia,
      orm: orm, unidad: unidad, planKg: planKg, realKg: updated,
    );
  }

  Map<String, dynamic> toJson() => {
    'grupo': grupo, 'nombre': nombre, 'dia': dia,
    'orm': orm, 'unidad': unidad,
    'planKg': planKg, 'realKg': realKg,
  };

  factory WeeklyLoad.fromJson(Map<String, dynamic> j) => WeeklyLoad(
    grupo: j['grupo'] ?? '', nombre: j['nombre'] ?? '',
    dia: j['dia'] ?? '', orm: (j['orm'] as num?)?.toDouble() ?? 0,
    unidad: j['unidad'] ?? '',
    planKg: (j['planKg'] as List? ?? []).map((v) => (v as num).toDouble()).toList(),
    realKg: (j['realKg'] as List? ?? []).map((v) => (v as num?)?.toDouble()).toList(),
  );
}
