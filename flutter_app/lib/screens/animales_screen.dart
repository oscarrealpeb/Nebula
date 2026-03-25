import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../controllers/app_controller.dart';

class AnimalesScreen extends StatefulWidget {
  const AnimalesScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AnimalesScreen> createState() => _AnimalesScreenState();
}

class _AnimalesScreenState extends State<AnimalesScreen> {
  final AudioPlayer player = AudioPlayer();
  final Random random = Random();

  int animalIndex = 0;
  int factIndex = 0;

  final List<Map<String, dynamic>> animales = [
    {
      'nombre': 'perro',
      'datos': [
        '¿Sabías que los perros tienen un olfato mucho más fuerte que los humanos? Gracias a esto pueden encontrar personas o cosas escondidas.',
        '¿Sabías que los perros pueden aprender muchos trucos y órdenes? Ellos entienden palabras y también los gestos de sus dueños.',
        '¿Sabías que los perros son animales muy leales? Les gusta estar cerca de las personas que quieren.',
        '¿Sabías que existen perros de muchos tamaños y razas diferentes? Algunos son tan pequeños como un juguete y otros son muy grandes.',
        '¿Sabías que los perros pueden sentir cuando una persona está triste o feliz? Por eso muchas veces intentan consolar a sus dueños.'
      ]
    },
    {
      'nombre': 'gato',
      'datos': [
        '¿Sabías que los gatos duermen la mayor parte del día? Ellos descansan mucho para tener energía cuando están activos.',
        '¿Sabías que los gatos pueden ver mejor que los humanos en la oscuridad? Sus ojos están adaptados para la noche.',
        '¿Sabías que los gatos son muy ágiles y pueden saltar varias veces su tamaño? Esto les ayuda a escapar o a cazar.',
        '¿Sabías que los gatos se comunican con maullidos y movimientos de su cola? Así expresan lo que sienten.',
        '¿Sabías que los gatos se limpian solos con su lengua todos los días? Esto les ayuda a mantenerse limpios y ordenados.'
      ]
    },
    {
      'nombre': 'conejo',
      'datos': [
        '¿Sabías que los conejos tienen orejas muy largas y sensibles? Las usan para escuchar peligros desde lejos.',
        '¿Sabías que los conejos comen principalmente verduras y plantas? Les encantan las zanahorias y las hojas verdes.',
        '¿Sabías que los conejos pueden saltar muy alto y muy rápido? Esto les ayuda a escapar de los depredadores.',
        '¿Sabías que los conejos son animales tranquilos y silenciosos? Prefieren lugares seguros y calmados.',
        '¿Sabías que los dientes de los conejos crecen toda su vida? Por eso necesitan morder cosas duras para desgastarlos.'
      ]
    },
    {
      'nombre': 'vaca',
      'datos': [
        '¿Sabías que las vacas producen la leche que muchas personas beben? Esa leche también se usa para hacer queso y yogur.',
        '¿Sabías que las vacas pasan gran parte del día comiendo pasto? Necesitan mucha comida para mantenerse fuertes.',
        '¿Sabías que las vacas tienen cuatro estómagos para digerir mejor la comida? Esto les permite aprovechar las plantas que comen.',
        '¿Sabías que las vacas pueden reconocer a otras vacas y a las personas? Ellas tienen muy buena memoria.',
        '¿Sabías que las vacas hacen el sonido muuu para comunicarse? Lo usan para llamar a otras vacas o a sus crías.'
      ]
    },
    {
      'nombre': 'caballo',
      'datos': [
        '¿Sabías que los caballos pueden correr muy rápido en distancias largas? Por eso han sido usados en carreras y viajes durante muchos años.',
        '¿Sabías que los caballos pueden dormir tanto acostados como de pie? Esto les permite descansar sin dejar de estar atentos.',
        '¿Sabías que los caballos tienen una memoria muy buena? Pueden recordar lugares y personas durante mucho tiempo.',
        '¿Sabías que los caballos se comunican con sonidos y con el movimiento de sus orejas y cola? Así muestran si están tranquilos o nerviosos.',
        '¿Sabías que los caballos han ayudado a los humanos en trabajos y transporte desde hace miles de años? Han sido compañeros muy importantes.'
      ]
    },
    {
      'nombre': 'elefante',
      'datos': [
        '¿Sabías que los elefantes son los animales terrestres más grandes del mundo? Su enorme cuerpo los hace muy fuertes.',
        '¿Sabías que los elefantes usan su trompa para comer, beber y agarrar objetos? Es como una mano muy larga y flexible.',
        '¿Sabías que los elefantes tienen una memoria increíble? Pueden recordar caminos y otros elefantes durante muchos años.',
        '¿Sabías que los elefantes viven en grupos familiares liderados por una hembra mayor? Ella guía a los demás y los protege.',
        '¿Sabías que los elefantes se bañan con agua y barro para refrescarse y proteger su piel del sol? Es parte de su rutina diaria.'
      ]
    },
    {
      'nombre': 'leon',
      'datos': [
        '¿Sabías que el león es conocido como el rey de la selva? Es un animal fuerte y respetado por otros animales.',
        '¿Sabías que los leones viven en grupos llamados manadas? En ellas trabajan juntos para cazar y protegerse.',
        '¿Sabías que los leones machos tienen una melena alrededor de su cabeza? Esta los hace parecer más grandes y fuertes.',
        '¿Sabías que los leones pueden rugir muy fuerte? Su rugido se puede escuchar a varios kilómetros de distancia.',
        '¿Sabías que los leones descansan muchas horas al día? Guardan su energía para cazar cuando lo necesitan.'
      ]
    },
    {
      'nombre': 'tigre',
      'datos': [
        '¿Sabías que cada tigre tiene un patrón de rayas único? Es como su huella digital.',
        '¿Sabías que los tigres son excelentes cazadores? Usan su fuerza y sigilo para atrapar a sus presas.',
        '¿Sabías que los tigres pueden nadar muy bien? Les gusta el agua y pueden cruzar ríos fácilmente.',
        '¿Sabías que los tigres viven solos la mayor parte del tiempo? Solo se juntan con otros en ciertas ocasiones.',
        '¿Sabías que los tigres son los felinos más grandes del mundo? Pueden ser muy fuertes y rápidos.'
      ]
    },
    {
      'nombre': 'jirafa',
      'datos': [
        '¿Sabías que la jirafa es el animal más alto del mundo? Su largo cuello le ayuda a alcanzar hojas en árboles altos.',
        '¿Sabías que las jirafas tienen manchas únicas en su piel? Ninguna jirafa tiene el mismo patrón.',
        '¿Sabías que las jirafas usan su lengua larga para agarrar hojas? Su lengua puede medir más de 40 centímetros.',
        '¿Sabías que las jirafas pueden correr a gran velocidad? A pesar de ser altas, son muy rápidas.',
        '¿Sabías que las jirafas casi no necesitan dormir mucho? Descansan en pequeños periodos durante el día.'
      ]
    },
    {
      'nombre': 'mono',
      'datos': [
        '¿Sabías que los monos viven en los árboles? Allí se sienten seguros y pueden moverse con facilidad.',
        '¿Sabías que los monos usan sus manos y cola para agarrar cosas? Esto les ayuda a trepar y balancearse.',
        '¿Sabías que los monos son muy inteligentes? Pueden aprender y resolver problemas.',
        '¿Sabías que los monos viven en grupos? Se ayudan entre ellos para protegerse.',
        '¿Sabías que los monos pueden saltar de rama en rama? Son muy ágiles y rápidos en los árboles.'
      ]
    },
    {
      'nombre': 'oso',
      'datos': [
        '¿Sabías que algunos osos hibernan durante el invierno? Duermen por mucho tiempo para ahorrar energía.',
        '¿Sabías que los osos comen frutas, miel y pescado? Son animales que comen diferentes tipos de comida.',
        '¿Sabías que los osos son muy fuertes? Pueden levantar cosas pesadas con facilidad.',
        '¿Sabías que los osos tienen un excelente sentido del olfato? Pueden encontrar comida desde lejos.',
        '¿Sabías que los osos pueden nadar muy bien? Usan su fuerza para moverse en el agua.'
      ]
    },
    {
      'nombre': 'delfin',
      'datos': [
        '¿Sabías que los delfines son animales muy inteligentes? Pueden aprender trucos y comunicarse entre ellos.',
        '¿Sabías que los delfines viven en el agua todo el tiempo? Son mamíferos que respiran aire como nosotros.',
        '¿Sabías que los delfines usan sonidos para comunicarse? Emiten silbidos y chasquidos.',
        '¿Sabías que los delfines pueden saltar fuera del agua? Lo hacen para jugar o comunicarse.',
        '¿Sabías que los delfines viven en grupos llamados manadas? Se cuidan entre ellos.'
      ]
    },
    {
      'nombre': 'tucan',
      'datos': [
        '¿Sabías que el tucán tiene un pico grande y muy colorido? Su pico es ligero y no pesa tanto como parece.',
        '¿Sabías que los tucanes viven en la selva? Prefieren lugares con muchos árboles.',
        '¿Sabías que los tucanes comen principalmente frutas? También pueden comer insectos pequeños.',
        '¿Sabías que el pico del tucán le ayuda a alcanzar comida? Puede tomar frutas que están lejos.',
        '¿Sabías que los tucanes hacen sonidos para comunicarse? Usan estos sonidos para hablar con otros tucanes.'
      ]
    },
    {
      'nombre': 'pinguino',
      'datos': [
        '¿Sabías que los pingüinos no pueden volar? Sus alas están adaptadas para nadar.',
        '¿Sabías que los pingüinos son excelentes nadadores? Se mueven rápido dentro del agua.',
        '¿Sabías que los pingüinos viven en lugares muy fríos? Su cuerpo está preparado para el hielo.',
        '¿Sabías que los pingüinos caminan de forma graciosa? Se balancean de un lado a otro.',
        '¿Sabías que los pingüinos cuidan mucho a sus crías? Ambos padres ayudan a protegerlas.'
      ]
    },
    {
      'nombre': 'tortuga',
      'datos': [
        '¿Sabías que las tortugas tienen un caparazón duro que las protege? Es como una armadura natural.',
        '¿Sabías que las tortugas pueden vivir muchos años? Algunas viven más de cien años.',
        '¿Sabías que las tortugas caminan lentamente? Se toman su tiempo para moverse.',
        '¿Sabías que algunas tortugas viven en el agua y otras en la tierra? Existen diferentes tipos.',
        '¿Sabías que las tortugas pueden esconderse dentro de su caparazón? Lo hacen para protegerse del peligro.'
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _generarContenido();
  }

  void _generarContenido() {
    animalIndex = random.nextInt(animales.length);
    factIndex = random.nextInt(5);
    setState(() {});
    Future.delayed(const Duration(milliseconds: 200), () {
      _reproducirAudio();
    });
  }

  Future<void> _reproducirAudio() async {
    String narrator = widget.controller.selectedNarratorId;
    String voice = narrator == 'narrator_1' ? 'm' : 'f';
    String animal = animales[animalIndex]['nombre'];
    String path =
        'sounds/explora/animales/$animal/${voice}_${factIndex + 1}.mp3';

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
    final animal = animales[animalIndex];
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Animales')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Image.asset(
                'assets/images/explora/animales/${animal['nombre']}.png',
                fit: BoxFit.contain,
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
                    animal['datos'][factIndex],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22, // MÁS GRANDE
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
