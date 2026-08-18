class MealTiming {
  final String momento;   // "Pre-entreno", "Post-entreno", etc.
  final String descripcion;
  final int proteina;
  final int carbos;
  final int grasas;
  final int calorias;

  MealTiming({
    required this.momento,
    required this.descripcion,
    required this.proteina,
    required this.carbos,
    required this.grasas,
    required this.calorias,
  });

  Map<String, dynamic> toJson() => {
    'momento': momento, 'descripcion': descripcion,
    'proteina': proteina, 'carbos': carbos,
    'grasas': grasas, 'calorias': calorias,
  };

  factory MealTiming.fromJson(Map<String, dynamic> j) => MealTiming(
    momento: j['momento'] ?? '', descripcion: j['descripcion'] ?? '',
    proteina: j['proteina'] ?? 0, carbos: j['carbos'] ?? 0,
    grasas: j['grasas'] ?? 0, calorias: j['calorias'] ?? 0,
  );
}

class NutritionPlan {
  final int proteinaTotal;
  final int carbosTotal;
  final int grasasTotal;
  final int caloriasTotal;
  final List<MealTiming> comidas;
  final List<String> suplementos;

  NutritionPlan({
    required this.proteinaTotal,
    required this.carbosTotal,
    required this.grasasTotal,
    required this.caloriasTotal,
    required this.comidas,
    required this.suplementos,
  });

  // Plan default basado en perfil de Julian (91 kg, 24 años, pivote)
  factory NutritionPlan.defaultPlan() => NutritionPlan(
    proteinaTotal: 195,
    carbosTotal: 450,
    grasasTotal: 90,
    caloriasTotal: 3900,
    suplementos: [
      'Creatina monohidrato — 5 g/día (siempre, no ciclar)',
      'Proteína whey — post-entreno si no alcanzas proteína del día',
      'Omega-3 — 2 g/día con comida',
      'Vitamina D3 — 2000 IU con desayuno',
      'Magnesio glicinato — 300 mg antes de dormir',
      'Cafeína — 200 mg pre-entrenamiento (no después de 3 pm)',
    ],
    comidas: [
      MealTiming(
        momento: '🌅 Desayuno (7:00 am)',
        descripcion: 'Avena 100g + 4 huevos + 1 banano + leche 200ml',
        proteina: 45, carbos: 95, grasas: 18, calorias: 730,
      ),
      MealTiming(
        momento: '⚡ Pre-entreno (30-45 min antes)',
        descripcion: 'Arroz blanco 150g + pollo 120g + cafeína 200mg',
        proteina: 38, carbos: 75, grasas: 5, calorias: 495,
      ),
      MealTiming(
        momento: '🔄 Intra-entreno',
        descripcion: 'Bebida de carbohidratos 40-60g (Gatorade o maltodextrina)',
        proteina: 0, carbos: 50, grasas: 0, calorias: 200,
      ),
      MealTiming(
        momento: '💪 Post-entreno (dentro de 30 min)',
        descripcion: 'Whey 40g + banano 2 unidades + leche descremada 300ml',
        proteina: 50, carbos: 65, grasas: 5, calorias: 510,
      ),
      MealTiming(
        momento: '🍽 Almuerzo (1-2h post-entreno)',
        descripcion: 'Arroz 200g + proteína magra 180g + vegetales + aceite 15ml',
        proteina: 50, carbos: 90, grasas: 22, calorias: 760,
      ),
      MealTiming(
        momento: '🌙 Cena (2h antes de dormir)',
        descripcion: 'Pasta 100g + salmón 150g o pollo 200g + aguacate medio',
        proteina: 48, carbos: 75, grasas: 25, calorias: 745,
      ),
      MealTiming(
        momento: '🛌 Antes de dormir',
        descripcion: 'Cottage cheese 200g o caseína 30g + magnesio',
        proteina: 24, carbos: 8, grasas: 5, calorias: 175,
      ),
    ],
  );

  Map<String, dynamic> toJson() => {
    'proteinaTotal': proteinaTotal, 'carbosTotal': carbosTotal,
    'grasasTotal': grasasTotal, 'caloriasTotal': caloriasTotal,
    'comidas': comidas.map((c) => c.toJson()).toList(),
    'suplementos': suplementos,
  };

  factory NutritionPlan.fromJson(Map<String, dynamic> j) => NutritionPlan(
    proteinaTotal: j['proteinaTotal'] ?? 0,
    carbosTotal: j['carbosTotal'] ?? 0,
    grasasTotal: j['grasasTotal'] ?? 0,
    caloriasTotal: j['caloriasTotal'] ?? 0,
    comidas: (j['comidas'] as List? ?? [])
        .map((c) => MealTiming.fromJson(c as Map<String, dynamic>))
        .toList(),
    suplementos: List<String>.from(j['suplementos'] ?? []),
  );
}
