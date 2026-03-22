import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/cosmic_background.dart';
import 'animales_screen.dart';

class ExploreLearnScreen extends StatelessWidget {
  const ExploreLearnScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Explora y aprende'),
      ),
      body: CosmicBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _CategoryCard(
                  title: 'Animales',
                  imagePath: 'assets/images/explora/animales.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AnimalesScreen(controller: controller),
                      ),
                    );
                  },
                ),
                _CategoryCard(
                  title: 'Universo',
                  imagePath: 'assets/images/explora/universo.png',
                  onTap: () {},
                ),
                _CategoryCard(
                  title: 'Historia',
                  imagePath: 'assets/images/explora/historia.png',
                  onTap: () {},
                ),
                _CategoryCard(
                  title: 'Arte',
                  imagePath: 'assets/images/explora/arte.png',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  final String title;
  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black, // visible
          ),
        ),
      ],
    );
  }
}