import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'discovery_welcome_page.dart';
import 'rapt_dashboard_page.dart';
import 'recipe_prompt_page.dart'; // Assuming this exists or will exist
import 'user_profile_page.dart';

class BrewEntryPage extends StatelessWidget {
  const BrewEntryPage({super.key});

  static const String routeName = '/';

  void _openRoute(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
  }

  Future<void> _openStudio(BuildContext context) async {
    final uri = Uri.parse('http://127.0.0.1:54323/');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konnte Studio nicht öffnen.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 20,
              right: 20,
              child: Image.asset(
                'assets/icon_small.png',
                height: 49,
                filterQuality: FilterQuality.none,
                semanticLabel: 'AiBrewGenius',
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _EntryButton(
                      label: 'Users profil',
                      onPressed: () =>
                          _openRoute(context, UserProfilePage.routeName),
                    ),
                    const SizedBox(height: 18),
                    _EntryButton(
                      label: 'Currently Brewing',
                      onPressed: () => _openRoute(context, RaptDashboardPage.routeName),
                    ),
                    const SizedBox(height: 18),
                    _EntryButton(
                      label: 'Studio',
                      onPressed: () => _openStudio(context),
                    ),
                    const SizedBox(height: 18),
                    _EntryButton(
                      label: 'Start, entdecken wir ein neues Bier',
                      onPressed: () => _openRoute(
                        context,
                        DiscoveryWelcomePage.routeName,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _EntryButton(
                      label: 'Freie Text beschreibung',
                      onPressed: () =>
                          _openRoute(context, RecipePromptPage.routeName),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryButton extends StatelessWidget {
  const _EntryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          textStyle: const TextStyle(fontSize: 16),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
