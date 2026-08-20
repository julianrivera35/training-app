class Exercise {
  final String bloque;
  final String nombre;
  final String peso;
  final String reps;
  final String series;
  final String descanso;
  final String instruccion;
  final String seccion;
  final String dia;
  bool hecho;
  double? pesoReal;

  Exercise({
    required this.bloque,
    required this.nombre,
    this.peso = '',
    this.reps = '',
    this.series = '',
    this.descanso = '',
    this.instruccion = '',
    this.seccion = '',
    this.dia = '',
    this.hecho = false,
    this.pesoReal,
  });

  Map<String, dynamic> toJson() => {
    'bloque': bloque, 'nombre': nombre, 'peso': peso,
    'reps': reps, 'series': series, 'descanso': descanso,
    'instruccion': instruccion, 'seccion': seccion, 'dia': dia,
    'hecho': hecho, 'pesoReal': pesoReal,
  };

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    bloque: j['bloque'] ?? '', nombre: j['nombre'] ?? '',
    peso: j['peso'] ?? '', reps: j['reps'] ?? '',
    series: j['series'] ?? '', descanso: j['descanso'] ?? '',
    instruccion: j['instruccion'] ?? '', seccion: j['seccion'] ?? '',
    dia: j['dia'] ?? '', hecho: j['hecho'] ?? false,
    pesoReal: (j['pesoReal'] as num?)?.toDouble(),
  );
}

class TrainingDay {
  final String name;
  final List<Exercise> exercises;

  TrainingDay({required this.name, required this.exercises});

  Map<String, dynamic> toJson() => {
    'name': name,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory TrainingDay.fromJson(Map<String, dynamic> j) => TrainingDay(
    name: j['name'] ?? '',
    exercises: (j['exercises'] as List? ?? [])
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
