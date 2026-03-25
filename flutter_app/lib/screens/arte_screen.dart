import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../controllers/app_controller.dart';

class ArteScreen extends StatefulWidget {
  const ArteScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ArteScreen> createState() => _ArteScreenState();
}

class _ArteScreenState extends State<ArteScreen> {
  final AudioPlayer player = AudioPlayer();
  final Random random = Random();

  int itemIndex = 0;
  int factIndex = 0;

  final List<Map<String, dynamic>> arte = [
    {
      'nombre': 'mona_lisa',
      'titulo': 'La Mona Lisa',
      'datos': [
        'La Mona Lisa fue pintada por Leonardo da Vinci hace más de 500 años. Es una de las obras más famosas de toda la historia.',
        'Su sonrisa parece cambiar dependiendo de cómo la mires. A veces parece feliz y otras veces misteriosa.',
        'Este cuadro se encuentra en el museo del Louvre en Francia. Miles de personas lo visitan todos los días.',
        'La Mona Lisa no tiene cejas visibles en la pintura. Esto ha generado mucha curiosidad entre los expertos.',
        'Es considerada una de las pinturas más importantes del mundo. Su fama ha crecido durante siglos.'
      ]
    },
    {
      'nombre': 'noche_estrellada',
      'titulo': 'La Noche Estrellada',
      'datos': [
        'Esta pintura fue creada por Vincent van Gogh mientras estaba en un hospital. Desde allí observaba el cielo por la ventana.',
        'El cielo tiene formas onduladas y llenas de movimiento. Esto hace que la obra se vea muy viva.',
        'Es una de las pinturas más reconocidas del arte moderno. Muchas personas la identifican fácilmente.',
        'Van Gogh usaba colores brillantes para expresar emociones. No pintaba solo lo que veía, sino lo que sentía.',
        'Representa un paisaje nocturno con estrellas muy llamativas. La escena parece casi un sueño.'
      ]
    },
    {
      'nombre': 'girasoles',
      'titulo': 'Los Girasoles',
      'datos': [
        'Vincent van Gogh pintó varias versiones de los girasoles. Todas tienen colores muy intensos.',
        'El color amarillo es el protagonista en estas obras. Transmite energía y alegría.',
        'Estas pinturas son de las más famosas del artista. Son reconocidas en todo el mundo.',
        'Los girasoles representan la luz y la vida. Van Gogh los pintaba con mucha pasión.',
        'En la vida real, los girasoles siguen la luz del sol. Esto los hace aún más especiales.'
      ]
    },
    {
      'nombre': 'el_grito',
      'titulo': 'El Grito',
      'datos': [
        'Esta pintura fue creada por el artista Edvard Munch. Es muy famosa por su expresión intensa.',
        'Representa una sensación de miedo o ansiedad. La figura parece estar gritando con fuerza.',
        'El cielo rojo fue inspirado en un atardecer real. Ese color hace que la escena sea más impactante.',
        'Existen varias versiones de esta obra. Todas muestran la misma emoción fuerte.',
        'Es una de las imágenes más conocidas del arte. Muchas personas la reconocen al instante.'
      ]
    },
    {
      'nombre': 'joven_perla',
      'titulo': 'La Joven de la Perla',
      'datos': [
        'Esta pintura fue hecha por Johannes Vermeer. Es muy admirada por su belleza y detalle.',
        'La joven lleva un pendiente de perla brillante. Este detalle llama mucho la atención.',
        'A veces la llaman la Mona Lisa del norte. Esto se debe a su misterio.',
        'El fondo oscuro hace resaltar el rostro. La luz ilumina suavemente su cara.',
        'No se sabe exactamente quién era la joven. Eso la hace aún más interesante.'
      ]
    },
    {
      'nombre': 'da_vinci',
      'titulo': 'Leonardo da Vinci',
      'datos': [
        'Leonardo da Vinci pintó la famosa Mona Lisa. Fue uno de los artistas más importantes del Renacimiento.',
        'También fue inventor y científico. Le gustaba estudiar muchas cosas diferentes.',
        'Investigaba el cuerpo humano con mucho detalle. Esto le ayudaba a mejorar sus pinturas.',
        'Escribía sus notas al revés como si fueran un espejo. Esto hacía sus escritos únicos.',
        'Es considerado un genio de la historia. Sus ideas siguen siendo admiradas hoy en día.'
      ]
    },
    {
      'nombre': 'van_gogh',
      'titulo': 'Vincent van Gogh',
      'datos': [
        'Van Gogh pintó más de 800 cuadros en su vida. Su estilo es muy fácil de reconocer.',
        'Usaba colores brillantes y pinceladas fuertes. Sus obras transmiten muchas emociones.',
        'Es uno de los artistas más famosos del mundo. Aunque no fue reconocido en vida.',
        'Muchas de sus pinturas se hicieron famosas después de su muerte. Hoy son muy valiosas.',
        'Creó obras como La noche estrellada y Los girasoles. Estas son conocidas en todo el mundo.'
      ]
    },
    {
      'nombre': 'picasso',
      'titulo': 'Pablo Picasso',
      'datos': [
        'Pablo Picasso fue un artista español muy famoso. Comenzó a dibujar desde niño.',
        'Creó un estilo llamado cubismo. En este estilo las figuras se ven diferentes.',
        'Le gustaba experimentar con nuevas formas. Siempre buscaba innovar en el arte.',
        'Creó una gran cantidad de obras durante su vida. Su creatividad parecía no tener límites.',
        'Sus pinturas muestran rostros y objetos de manera única. Son fáciles de reconocer.'
      ]
    },
    {
      'nombre': 'frida_kahlo',
      'titulo': 'Frida Kahlo',
      'datos': [
        'Frida Kahlo fue una artista mexicana muy reconocida. Sus obras son muy personales.',
        'Pintó muchos autorretratos. En ellos mostraba sus emociones.',
        'Sus pinturas reflejan su vida y experiencias. Cada obra cuenta una historia.',
        'Representa la fuerza y la autenticidad en el arte. Su vida y obra siguen inspirando a muchas personas.',
        'Su estilo es muy colorido y original. Es única en el mundo del arte.'
      ]
    },
    {
      'nombre': 'dali',
      'titulo': 'Salvador Dalí',
      'datos': [
        'Salvador Dalí fue un artista español muy creativo. Tenía una imaginación muy grande.',
        'Sus pinturas muestran escenas extrañas y soñadoras. Parecen salidas de un sueño.',
        'Es famoso por los relojes derretidos. Esta imagen es muy reconocida.',
        'Tenía una forma muy distinta de ver el mundo. Sus ideas rompían con lo común.',
        'Es uno de los artistas más importantes del surrealismo. Su arte sigue sorprendiendo.'
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _generarContenido();
  }

  void _generarContenido() {
    itemIndex = random.nextInt(arte.length);
    factIndex = random.nextInt(5);
    setState(() {});
    Future.delayed(const Duration(milliseconds: 200), () {
      _reproducirAudio();
    });
  }

  Future<void> _reproducirAudio() async {
    String narrator = widget.controller.selectedNarratorId;
    String voice = narrator == 'narrator_1' ? 'm' : 'f';
    String item = arte[itemIndex]['nombre'];

    String path = 'sounds/explora/arte/$item/${voice}_${factIndex + 1}.mp3';

    await player.stop();
    await player.play(AssetSource(path));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = arte[itemIndex];
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Arte')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      'assets/images/explora/arte/${item['nombre']}.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['titulo'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 3,
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
                child: Center(
                  child: Text(
                    item['datos'][factIndex],
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
