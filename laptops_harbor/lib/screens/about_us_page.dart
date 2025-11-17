import 'package:flutter/material.dart';
import 'package:laptops_harbor/widgets/header.dart';
import 'package:laptops_harbor/widgets/footer.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});
  static const String routeName = '/about-us';

  @override
  Widget build(BuildContext context) {
    final teamMembers = [

  {
    'name': 'Samya',
    'role': 'Flutter Developer',
    'bio':
        'A passionate tech enthusiast and skilled Flutter developer with years of experience in crafting seamless and high-performing mobile applications. Dedicated to building intuitive and elegant solutions for LaptopHarbor users.',
  },
  {
    'name': 'Sana',
    'role': 'Lead Developer',
    'bio':
        'A tech innovator focused on developing smooth, user-friendly digital experiences. Passionate about building reliable and modern web and app solutions that make exploring and purchasing laptops effortless.',
  },
];


    return Scaffold(
      drawer: laptopsharborHeader.buildDrawer(context),
      body: Column(
        children: [
          const laptopsharborHeader(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'About LaptopHarbor',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'It is our pleasure to welcome you to LaptopHarbor — '
                            'the best online source for laptops that suit your every need, preference, and budget. '
                            'Our top priority is to simplify the search for a laptop by gathering the most popular brands, models, and gadgets on one platform. '
                            'Whether you are a student, professional, programmer, or gamer – you can search, compare, and buy the best laptop for yourself with ease and confidence.',
                            style: TextStyle(fontSize: 16, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'What Do We Offer?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '• A wide product range – the latest laptops from reputable suppliers around the world.\n'
                            '• Smart search and filters – quickly select laptops by brand, price range, and performance.\n'
                            '• Users’ reviews and ratings – decide better with real people’s experiences.\n'
                            '• Secure shopping – safe online payment systems for all devices.\n'
                            '• Personalized experience – manage profiles, create wishlists, and track orders with ease.',
                            style: TextStyle(fontSize: 16, height: 1.5),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Our Vision',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'To become the most trusted and leading online laptop shopping platform through innovation, quality, and customer satisfaction. '
                            'Our vision is to build a bridge between technology providers and users through dialogue, convenience, and reliability. '
                            'At LaptopHarbor, technology truly meets convenience.',
                            style: TextStyle(fontSize: 16, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Meet Our Team',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...teamMembers.map(
                            (m) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(m['name']![0]),
                                ),
                                title: Text(m['name']!),
                                subtitle: Text('${m['role']}\n${m['bio']}'),
                                isThreeLine: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const laptopsharborfooter(),
        ],
      ),
    );
  }
}
