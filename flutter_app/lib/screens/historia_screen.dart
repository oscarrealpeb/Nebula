import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../controllers/app_controller.dart';

class HistoriaScreen extends StatefulWidget {
  const HistoriaScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<HistoriaScreen> createState() => _HistoriaScreenState();
}

class _HistoriaScreenState extends State<HistoriaScreen> {
  final AudioPlayer player = AudioPlayer();
  final Random random = Random();

  int temaIndex = 0;
  int factIndex = 0;

  final List<Map<String, dynamic>> temasHistoria = [
  {
    'nombre': 'dinosaurios',
    'datos': [
      '¿Sabías que algunos dinosaurios no tenían piel como los reptiles, sino plumas suaves como las de un pájaro? Imagina un dinosaurio grande caminando… ¡pero cubierto de plumas!',
      '¡Escucha esto! El Tiranosaurio Rex tenía dientes tan grandes como un plátano, y cuando abría la boca… parecía una trampa gigante. ¡Sus mordidas eran súper poderosas!',
      '¿Te imaginas estar al lado de un dinosaurio tan largo como tres buses juntos? Algunos eran tan enormes que su cuello parecía una torre moviéndose lentamente.',
      '¿Sabías que no todos los dinosaurios eran feroces? Algunos eran tranquilos y pasaban el día comiendo hojas, como si fueran vacas gigantes del pasado.',
      '¡Dato sorprendente! Los dinosaurios vivieron hace tantísimo tiempo… que ni los humanos existían todavía. Es como pensar en un mundo completamente diferente al nuestro.',
    ]
  },
  {
    'nombre': 'ciudades',
    'datos': [
      '¿Sabías que las primeras ciudades no tenían edificios altos, sino casas hechas de barro y paja? Imagina caminar por calles de tierra rodeado de casitas simples.',
      '¡Escucha esto! En las ciudades ya existían mercados donde las personas intercambiaban comida y objetos. Era como una gran feria todos los días.',
      '¿Te imaginas vivir dentro de una ciudad rodeada por muros gigantes? Los construían para protegerse de peligros.',
      '¿Sabías que las personas empezaron a vivir juntas para ayudarse entre todos? Así nació la idea de comunidad.',
      '¡Dato curioso! En las ciudades aparecieron las primeras reglas… como si fueran las primeras "normas del juego" para convivir.',
    ]
  },
  {
    'nombre': 'piratas',
    'datos': [
      '¿Sabías que los piratas escondían tesoros en islas lejanas y misteriosas? Imagina un cofre enterrado bajo la arena esperando ser encontrado.',
      '¡Escucha esto! Algunos mapas tenían una gran "X" que señalaba el lugar exacto del tesoro. ¡Como en una aventura secreta!',
      '¿Te imaginas viajar en un barco por el mar durante semanas sin ver tierra? Así vivían muchos piratas.',
      '¿Sabías que los cofres de los piratas estaban llenos de oro brillante y joyas? Cuando se abrían… ¡todo brillaba!',
      '¡Dato sorprendente! Algunos piratas tenían loros que los acompañaban en sus viajes. Siempre estaban sobre su hombro.',
    ]
  },
  {
    'nombre': 'egipcios',
    'datos': [
      '¿Sabías que las pirámides son construcciones gigantes hechas hace miles de años? Imagina bloques enormes apilados uno sobre otro hasta tocar el cielo.',
      '¡Escucha esto! Los egipcios convertían a sus reyes en momias para conservarlos. Las envolvían con muchas vendas.',
      '¿Te imaginas escribir usando dibujos en lugar de letras? Así eran los jeroglíficos.',
      '¿Sabías que el río Nilo era como una gran fuente de vida en medio del desierto? Gracias a él podían cultivar alimentos.',
      '¡Dato sorprendente! Algunas pirámides tienen más de 4,000 años… ¡y todavía siguen en pie!',
    ]
  },
  {
    'nombre': 'castillos',
    'datos': [
      '¿Sabías que los castillos tenían muros enormes y torres altísimas? Parecían gigantes de piedra vigilando todo.',
      '¡Escucha esto! Los caballeros usaban armaduras tan pesadas que casi no podían correr. Pero los protegían en batalla.',
      '¿Te imaginas cruzar un puente que se levanta como por magia? Así funcionaban algunos castillos.',
      '¿Sabías que los caballeros protegían al rey o la reina? Eran como guardianes valientes.',
      '¡Dato curioso! Dentro de los castillos había grandes salones donde se hacían banquetes. Mesas largas llenas de comida.',
    ]
  },
  {
    'nombre': 'vikingos',
    'datos': [
      '¿Sabías que los vikingos viajaban en barcos largos con cabezas de dragón? Parecían criaturas del mar.',
      '¡Escucha esto! Los vikingos navegaban por mares fríos y peligrosos. El viento y las olas eran enormes.',
      '¿Te imaginas vivir en un lugar donde hace mucho frío casi todo el tiempo? Así era el hogar de los vikingos.',
      '¿Sabías que no todos los vikingos usaban cascos con cuernos? Eso es más un mito que una realidad.',
      '¡Dato sorprendente! Los vikingos contaban historias de dioses y héroes poderosos. Como si fueran cuentos épicos.',
    ]
  },
  {
    'nombre': 'romanos',
    'datos': [
      '¿Sabías que los romanos construyeron caminos tan fuertes que algunos todavía existen? Parecen hechos para durar para siempre.',
      '¡Escucha esto! Los romanos tenían enormes coliseos donde se reunían miles de personas. Era como un estadio gigante.',
      '¿Te imaginas vestir solo con una tela larga llamada túnica? Así se vestían los romanos.',
      '¿Sabías que llevaban agua a las ciudades usando largos canales? El agua viajaba desde muy lejos.',
      '¡Dato sorprendente! El imperio romano era tan grande que cubría muchos países. Era como un mundo entero.',
    ]
  },
  {
    'nombre': 'exploradores',
    'datos': [
      '¿Sabías que algunos exploradores viajaban por meses sin saber a dónde llegarían? Era como una aventura sin mapa claro.',
      '¡Escucha esto! Los exploradores usaban las estrellas del cielo para orientarse. Miraban arriba para encontrar el camino.',
      '¡Escucha esto! Algunos exploradores escribían diarios todos los días. Así contaban lo que veían.',
      '¿Sabías que los barcos de los exploradores eran de madera y resistían tormentas fuertes? Las olas golpeaban sin parar.',
      '¿Sabías que los exploradores aprendían nuevas palabras de otros pueblos? Así podían comunicarse mejor.',
    ]
  },
  {
    'nombre': 'reyes',
    'datos': [
      '¿Sabías que los reyes vivían en palacios enormes con muchas habitaciones? Algunos parecían laberintos.',
      '¡Escucha esto! Las coronas que usaban los reyes brillaban con oro y piedras preciosas. Relucían con la luz.',
      '¡Escucha esto! Algunos reyes eran niños cuando empezaban a gobernar. Otros adultos los ayudaban.',
      '¿Sabías que las reinas también tomaban decisiones importantes? No solo los reyes mandaban.',
      '¡Atención! No todos los reyes eran buenos gobernantes. Algunos cometían errores.',
    ]
  },
  {
    'nombre': 'transportes',
    'datos': [
      '¿Sabías que los primeros trenes funcionaban con vapor y echaban humo? Parecían dragones de hierro.',
      '¡Escucha esto! Antes la gente viajaba en carros tirados por caballos. El viaje era lento pero constante.',
      '¿Sabías que los barcos antiguos usaban velas? El viento los hacía avanzar.',
      '¿Sabías que viajar antes podía tardar días o semanas? Nada era rápido.',
      '¿Te imaginas cruzar desiertos sin vehículos modernos? Las caravanas usaban camellos por su resistencia.',
    ]
  },
  {
    'nombre': 'civilizaciones',
    'datos': [
      '¿Sabías que algunas civilizaciones construyeron enormes ciudades sin máquinas? Solo con esfuerzo humano.',
      '¡Escucha esto! Algunas civilizaciones tenían formas de escribir únicas. Cada símbolo tenía un significado.',
      '¿Te imaginas crear un calendario observando el cielo? Así medían el tiempo las civilizaciones antiguas.',
      '¿Sabías que los egipcios sabían hacer cirugías simples? Usaban herramientas de metal.',
      '¡Atención! La civilización china inventó el papel y la pólvora. Estos inventos cambiaron el mundo.',
    ]
  },
  {
    'nombre': 'descubrimientos',
    'datos': [
      '¿Sabías que el fuego ayudó a los humanos a cocinar y calentarse? Cambió todo.',
      '¡Escucha esto! La rueda hizo posible mover cosas pesadas fácilmente. Como magia… pero real.',
      '¡Escucha esto! Los primeros relojes no tenían números. Solo marcaban sombras del sol.',
      '¿Sabías que la imprenta permitió hacer muchos libros iguales? Así más personas podían aprender.',
      '¡Sorprendente! Los primeros lentes se inventaron hace más de 700 años. Ayudaron a leer mejor.',
    ]
  },
  {
    'nombre': 'inventos',
    'datos': [
      '¿Sabías que el papel se inventó para escribir y guardar ideas? Antes se usaban piedras o pieles.',
      '¡Escucha esto! La brújula ayudó a no perderse en los viajes. Indicaba siempre el norte.',
      '¿Sabías que el reloj permitió medir el tiempo mejor? Así las personas se organizaban.',
      '¿Te imaginas escribir sin lápiz? Antes se escribía con plumas de aves.',
      '¡Atención! El ábaco ayudaba a hacer cuentas rápidas. Fue un invento para pensar mejor.',
    ]
  },
  {
    'nombre': 'ninos',
    'datos': [
      '¿Sabías que muchos niños ayudaban a sus familias desde pequeños? Trabajaban como los adultos.',
      '¡Escucha esto! Algunos niños no iban a la escuela. Aprendían observando a los adultos.',
      '¿Te imaginas crear tus propios juguetes con madera o piedras? Así jugaban los niños en la antigüedad.',
      '¿Sabías que los niños vestían como los adultos? No había ropa especial para niños.',
      '¡Atención! En muchas culturas, la infancia duraba poco. Pronto tenían responsabilidades.',
    ]
  },
  {
    'nombre': 'maravillas',
    'datos': [
      '¿Sabías que la Gran Muralla China es tan larga que atraviesa montañas y desiertos? Fue construida para proteger a un imperio entero.',
      '¡Escucha esto! El Coliseo Romano podía llenarse con miles de personas. Allí se realizaban grandes espectáculos.',
      '¿Te imaginas una ciudad entera hecha de piedra en lo alto de una montaña? Así es Machu Picchu.',
      '¿Sabías que el Taj Mahal fue construido por amor? Un emperador lo hizo para recordar a su esposa.',
      '¡Increíble! Chichén Itzá tiene una pirámide que crea sombras especiales. Parecen una serpiente en movimiento.',
    ]
  },
];
  @override
  void initState() {
    super.initState();
    _generarContenido();
  }

  void _generarContenido() {
    temaIndex = random.nextInt(temasHistoria.length);
    factIndex = random.nextInt(5);
    setState(() {});
    Future.delayed(const Duration(milliseconds: 200), () {
      _reproducirAudio();
    });
  }

  Future<void> _reproducirAudio() async {
    final narrator = widget.controller.selectedNarratorId.trim();
    final tema = temasHistoria[temaIndex]['nombre'];

    final prefijoAudio =
        _prefijoAudioPorTema[tema] ?? tema.substring(0, 3).toUpperCase();

    final fileName = narrator == 'narrator_2'
        ? 'm$prefijoAudio${factIndex + 1}.mp3'
        : '$prefijoAudio${factIndex + 1}.mp3';

    final path = 'sounds/explora/historia/$tema/$fileName';

    try {
      await player.stop();
      await player.play(AssetSource(path));
    } catch (_) {}
  }

  static const Map<String, String> _prefijoAudioPorTema = {
    'dinosaurios': 'DIN',
    'ciudades': 'CIU',
    'piratas': 'PIR',
    'egipcios': 'EGI',
    'castillos': 'CAS',
    'vikingos': 'VIK',
    'romanos': 'ROM',
    'exploradores': 'EXP',
    'reyes': 'REY',
    'transportes': 'TRA',
    'civilizaciones': 'CIV',
    'descubrimientos': 'DES',
    'inventos': 'INV',
    'ninos': 'NIN',
    'maravillas': 'MAR',
  };


  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final tema = temasHistoria[temaIndex];
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Historia')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Image.asset(
                'assets/images/explora/historia/${tema['nombre']}.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(2, 5))
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Text(
                          tema['datos'][factIndex],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                    ),
                  ),
            const SizedBox(height: 10),

            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _generarContenido,
                      icon: const Icon(Icons.shuffle, size: 28),
                      label: const Text(
                        'Cambiar',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _reproducirAudio,
                      icon: const Icon(Icons.volume_up, size: 28),
                      label: const Text(
                        'Escuchar',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
