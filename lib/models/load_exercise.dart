/// Un ejercicio de la hoja "CARGAS Y PROGRESIÓN". El peso planeado NO es
/// absoluto: se calcula como (1RM del usuario) × (% de la semana del bloque).
/// El 1RM lo ingresa el usuario en la app y se guarda aparte.
class LoadExercise {
  final String nombre;
  final String dia;

  const LoadExercise({required this.nombre, this.dia = ''});

  Map<String, dynamic> toJson() => {'nombre': nombre, 'dia': dia};

  factory LoadExercise.fromJson(Map<String, dynamic> j) =>
      LoadExercise(nombre: j['nombre'] ?? '', dia: j['dia'] ?? '');
}
