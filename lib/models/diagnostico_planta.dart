class DiagnosticoPlanta {
  final bool esPlanta;
  final String estado; // 'Sana', 'Posible afección' o 'No válido'
  final String titulo;
  final String recomendacion;

  const DiagnosticoPlanta({
    required this.esPlanta,
    required this.estado,
    required this.titulo,
    required this.recomendacion,
  });
}