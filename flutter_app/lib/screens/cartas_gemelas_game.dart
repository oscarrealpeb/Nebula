import 'package:flutter/material.dart';
import '../controllers/app_controller.dart';
import 'dart:math';

class CartasGemelasGame extends StatefulWidget {
  const CartasGemelasGame({
    super.key,
    required this.controller,
    required this.difficultyStars,
    required this.onGameCompleted,
  });

  final AppController controller;
  final int difficultyStars;
  final VoidCallback onGameCompleted;

  @override
  State<CartasGemelasGame> createState() => _CartasGemelasGameState();
}

class _CartasGemelasGameState extends State<CartasGemelasGame> {
  final List<String> allImages = [
    // animales
    "assets/images/cards/animales/abeja.png",
    "assets/images/cards/animales/ardilla.png",
    "assets/images/cards/animales/caballo.png",
    "assets/images/cards/animales/cabra.png",
    "assets/images/cards/animales/cobra.png",
    "assets/images/cards/animales/cocodrilo.png",
    "assets/images/cards/animales/elefante.png",
    "assets/images/cards/animales/ganso.png",
    "assets/images/cards/animales/gato.png",
    "assets/images/cards/animales/loro.png",
    "assets/images/cards/animales/oveja.png",
    "assets/images/cards/animales/perro.png",
    "assets/images/cards/animales/tigre.png",
    "assets/images/cards/animales/tortuga-marina.png",
    "assets/images/cards/animales/vaca.png",

    // frutas
    "assets/images/cards/frutas/cereza.png",
    "assets/images/cards/frutas/coco.png",
    "assets/images/cards/frutas/fresa.png",
    "assets/images/cards/frutas/kiwi-verde.png",
    "assets/images/cards/frutas/limon.png",
    "assets/images/cards/frutas/mango.png",
    "assets/images/cards/frutas/manzana.png",
    "assets/images/cards/frutas/maracuya.png",
    "assets/images/cards/frutas/naranja.png",
    "assets/images/cards/frutas/papaya.png",
    "assets/images/cards/frutas/pera.png",
    "assets/images/cards/frutas/pina.png",
    "assets/images/cards/frutas/platano.png",
    "assets/images/cards/frutas/sandia.png",
    "assets/images/cards/frutas/uva.png",

    // instrumentos
    "assets/images/cards/instrumentos/acordeon.png",
    "assets/images/cards/instrumentos/arpa.png",
    "assets/images/cards/instrumentos/bateria.png",
    "assets/images/cards/instrumentos/flauta.png",
    "assets/images/cards/instrumentos/guitarra-acustica.png",
    "assets/images/cards/instrumentos/guitarra-electrica.png",
    "assets/images/cards/instrumentos/maracas.png",
    "assets/images/cards/instrumentos/marimba.png",
    "assets/images/cards/instrumentos/pandereta.png",
    "assets/images/cards/instrumentos/piano.png",
    "assets/images/cards/instrumentos/platillo.png",
    "assets/images/cards/instrumentos/saxofono.png",
    "assets/images/cards/instrumentos/tambor.png",
    "assets/images/cards/instrumentos/trompeta.png",
    "assets/images/cards/instrumentos/violin.png",

    // transporte
    "assets/images/cards/transporte/autobus.png",
    "assets/images/cards/transporte/avion.png",
    "assets/images/cards/transporte/barco.png",
    "assets/images/cards/transporte/bicicleta.png",
    "assets/images/cards/transporte/carro-deportivo.png",
    "assets/images/cards/transporte/helicoptero.png",
    "assets/images/cards/transporte/moto.png",
    "assets/images/cards/transporte/submarino.png",
    "assets/images/cards/transporte/taxi.png",
    "assets/images/cards/transporte/tren.png",
  ];
  List<String> cards = [];
  List<bool> flipped = [];
  List<bool> matched = [];

  int? firstIndex;
  int? secondIndex;
  bool canTap = true;
  int? pressedIndex;

  @override
  void initState() {
    super.initState();
    _setupGame();
  }

  void _setupGame() {
    int pairs;

    if (widget.difficultyStars == 1) {
    pairs = 3; // 6 cartas
  } else if (widget.difficultyStars == 2) {
    pairs = 4; // 8 cartas
  } else {
    pairs = 5; // 10 cartas
  }

    List<String> shuffled = List.from(allImages);
    shuffled.shuffle(Random());

    List<String> selected = shuffled.take(pairs).toList();

    cards = [...selected, ...selected];
    cards.shuffle();

    flipped = List.generate(cards.length, (_) => false);
    matched = List.generate(cards.length, (_) => false);
  }

  void _tapCard(int index) async {
    if (!canTap || flipped[index] || matched[index]) return;

    setState(() {
      flipped[index] = true;
    });

    if (firstIndex == null) {
      firstIndex = index;
      return;
    }

    secondIndex = index;
    canTap = false;

    if (cards[firstIndex!] == cards[secondIndex!]) {
      setState(() {
        matched[firstIndex!] = true;
        matched[secondIndex!] = true;
      });

      firstIndex = null;
      secondIndex = null;
      canTap = true;

      /// verificar si terminó el juego
      if (matched.every((m) => m)) {
        canTap = false;
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onGameCompleted();
      }
    } else {
      await Future.delayed(const Duration(seconds: 1));
      canTap = true;

      setState(() {
        flipped[firstIndex!] = false;
        flipped[secondIndex!] = false;
      });

      firstIndex = null;
      secondIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    int columns;

    if (widget.difficultyStars == 1) {
  columns = 2; // 3 filas
} else if (widget.difficultyStars == 2) {
  columns = 2; // 4 filas
} else {
  columns = 2; // 6 filas
}
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          "¡Toca dos cartas y descubre si son pareja 🧠!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.controller.accentColor,
          ),
        ),
        const SizedBox(height: 0),
  
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: widget.difficultyStars == 1
            ? 0.90
            : widget.difficultyStars == 2
                ? 1.18
                : 1.55,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final visible = flipped[index] || matched[index];

        return GestureDetector(
            onTapDown: (_) {
              setState(() {
                pressedIndex = index;
              });
            },
            onTapUp: (_) {
              setState(() {
                pressedIndex = null;
              });
            },
            onTapCancel: () {
              setState(() {
                pressedIndex = null;
              });
            },
            onTap: () => _tapCard(index),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 120),
              scale: pressedIndex == index ? 0.93 : 1.0,
              child: Card(
              elevation: visible ? 2 : 8,
              color: visible
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  reverseDuration: Duration.zero,
                  transitionBuilder: (child, animation) {
                    final rotate = Tween(begin: 3.14, end: 0.0).animate(animation);
                    return AnimatedBuilder(
                      animation: rotate,
                      child: child,
                      builder: (context, child) {
                        return Transform(
                          transform: Matrix4.rotationY(rotate.value),
                          alignment: Alignment.center,
                          child: child,
                        );
                      },
                    );
                  },
                  child: Container(
                    key: ValueKey(visible),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(12),
                    child: visible
                        ? Image.asset(
                            cards[index],
                            fit: BoxFit.contain,
                          )
                        : Icon(
                            Icons.auto_awesome,
                            size: 42,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                  )
                ),
              ),
                       ),
          ),
        );
      },
    ),
),
],
);
  }
}
