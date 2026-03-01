class SkillGameLink {
  const SkillGameLink({
    required this.gameKey,
    required this.howItHelps,
  });

  final String gameKey;
  final String howItHelps;
}

class SkillInfo {
  const SkillInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.everydayExamples,
    required this.evaluationNotes,
    required this.relatedGames,
  });

  final String id;
  final String title;
  final String description;
  final String everydayExamples;
  final String evaluationNotes;
  final List<SkillGameLink> relatedGames;
}

const List<SkillInfo> skillCatalog = [
  SkillInfo(
    id: 'emotion_recognition',
    title: 'Reconocimiento emocional',
    description:
        'Capacidad para identificar emociones en expresiones faciales y contexto.',
    everydayExamples:
        'Reconocer si alguien esta feliz, triste o molesto en casa o escuela.',
    evaluationNotes:
        'Se evalua por exactitud, confusiones frecuentes, velocidad e independencia.',
    relatedGames: [
      SkillGameLink(
        gameKey: 'descubre_emocion',
        howItHelps:
            'El nino observa una cara y elige la emocion correcta entre opciones.',
      ),
    ],
  ),
  SkillInfo(
    id: 'visual_attention',
    title: 'Atencion visual',
    description:
        'Capacidad para enfocar la mirada y sostener la atencion en estimulos relevantes.',
    everydayExamples:
        'Seguir instrucciones mirando senales, objetos o expresiones del adulto.',
    evaluationNotes:
        'Se evalua por estabilidad de respuesta y reduccion de errores por distraccion.',
    relatedGames: [
      SkillGameLink(
        gameKey: 'descubre_emocion',
        howItHelps:
            'Entrena foco visual al discriminar detalles de rostro y contexto.',
      ),
      SkillGameLink(
        gameKey: 'cartas_gemelas',
        howItHelps:
            'Exige mantener atencion continua para ubicar pares en distintas posiciones.',
      ),
    ],
  ),
  SkillInfo(
    id: 'auditory_discrimination',
    title: 'Discriminacion auditiva',
    description:
        'Capacidad para diferenciar sonidos y asociarlos correctamente con su origen.',
    everydayExamples:
        'Distinguir sonidos de animales, instrumentos o ambiente en situaciones cotidianas.',
    evaluationNotes:
        'Se evalua por aciertos, latencia y tipos de sonido con mayor confusion.',
    relatedGames: [
      SkillGameLink(
        gameKey: 'conecta_sonidos',
        howItHelps:
            'El nino escucha un audio y diferencia cual opcion coincide con ese sonido.',
      ),
    ],
  ),
  SkillInfo(
    id: 'audio_visual_association',
    title: 'Asociacion audio-imagen',
    description:
        'Capacidad para vincular un sonido escuchado con su representacion visual.',
    everydayExamples:
        'Relacionar el timbre de puerta con la accion de abrir o buscar quien llego.',
    evaluationNotes:
        'Se evalua por precision, intentos y consistencia entre sesiones.',
    relatedGames: [
      SkillGameLink(
        gameKey: 'conecta_sonidos',
        howItHelps:
            'Conecta un estimulo auditivo con la imagen correcta entre distractores.',
      ),
    ],
  ),
  SkillInfo(
    id: 'expressive_language',
    title: 'Lenguaje expresivo',
    description:
        'Capacidad para producir palabras o expresiones funcionales en contexto.',
    everydayExamples:
        'Pedir objetos, nombrar personas o describir necesidades basicas.',
    evaluationNotes:
        'Se evalua por respuesta emitida, precision verbal y apoyos requeridos.',
    relatedGames: [
      SkillGameLink(
        gameKey: 'di_palabra',
        howItHelps:
            'Refuerza nombrar objetos y seleccionar la palabra correcta de forma activa.',
      ),
      SkillGameLink(
        gameKey: 'explora_aprende',
        howItHelps:
            'Promueve vocabulario funcional al reconocer categorias y nombrarlas.',
      ),
    ],
  ),
  SkillInfo(
    id: 'working_memory',
    title: 'Memoria de trabajo visual',
    description:
        'Capacidad para retener y manipular informacion visual en corto plazo.',
    everydayExamples:
        'Recordar ubicacion de objetos o pasos breves de una actividad diaria.',
    evaluationNotes:
        'Se evalua por errores, reintentos y tiempo total para completar tareas.',
    relatedGames: [
      SkillGameLink(
        gameKey: 'cartas_gemelas',
        howItHelps:
            'Obliga a recordar posiciones previas para encontrar pares con menos intentos.',
      ),
    ],
  ),
  SkillInfo(
    id: 'sequencing',
    title: 'Secuenciacion',
    description:
        'Capacidad para ordenar eventos, objetos o acciones en una secuencia logica.',
    everydayExamples:
        'Seguir rutinas como lavarse manos: abrir llave, enjabonarse, enjuagar y secar.',
    evaluationNotes:
        'Se evalua por aciertos de orden, errores de inversion y velocidad.',
    relatedGames: [
      SkillGameLink(
        gameKey: 'que_sigue',
        howItHelps:
            'Entrena ordenar pasos o patrones en la posicion correcta dentro de una serie.',
      ),
    ],
  ),
  SkillInfo(
    id: 'categorization',
    title: 'Categorizacion semantica',
    description:
        'Capacidad para agrupar elementos por su significado o funcion.',
    everydayExamples: 'Separar ropa, juguetes o alimentos por tipo de uso.',
    evaluationNotes:
        'Se evalua por precision por categoria y errores recurrentes.',
    relatedGames: [
      SkillGameLink(
        gameKey: 'donde_va',
        howItHelps:
            'Practica decidir en que categoria va cada elemento entre opciones.',
      ),
      SkillGameLink(
        gameKey: 'explora_aprende',
        howItHelps:
            'Refuerza asociaciones semanticas y clasificacion con contenido guiado.',
      ),
    ],
  ),
  SkillInfo(
    id: 'visuospatial_integration',
    title: 'Integracion visoespacial',
    description:
        'Capacidad para coordinar percepcion visual con organizacion espacial y accion.',
    everydayExamples:
        'Armar rompecabezas, ubicar objetos en el espacio o copiar formas simples.',
    evaluationNotes:
        'Se evalua por movimientos errados, tiempo de armado y necesidad de ayuda.',
    relatedGames: [
      SkillGameLink(
        gameKey: 'arma_imagen',
        howItHelps:
            'Entrena ubicar piezas en posiciones correctas para construir una imagen completa.',
      ),
    ],
  ),
];

const Map<String, List<String>> gameToSkillIds = {
  'descubre_emocion': ['emotion_recognition', 'visual_attention'],
  'conecta_sonidos': ['auditory_discrimination', 'audio_visual_association'],
  'di_palabra': ['expressive_language'],
  'cartas_gemelas': ['working_memory', 'visual_attention'],
  'que_sigue': ['sequencing'],
  'donde_va': ['categorization'],
  'arma_imagen': ['visuospatial_integration'],
  'explora_aprende': ['categorization', 'expressive_language'],
};

const Map<String, String> gameLabelByKey = {
  'descubre_emocion': 'Descubre',
  'conecta_sonidos': 'Conecta',
  'di_palabra': 'Dilo',
  'minijuegos': 'Minijuegos',
  'cartas_gemelas': 'Cartas gemelas',
  'que_sigue': 'Que sigue',
  'donde_va': 'Donde va',
  'arma_imagen': 'Arma la imagen',
  'explora_aprende': 'Explora',
};

SkillInfo? skillById(String id) {
  for (final skill in skillCatalog) {
    if (skill.id == id) return skill;
  }
  return null;
}
