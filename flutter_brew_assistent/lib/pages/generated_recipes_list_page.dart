import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_recipe.dart';
import 'recipe_completion_page.dart';

class GeneratedRecipesListPage extends StatefulWidget {
  const GeneratedRecipesListPage({super.key});

  @override
  State<GeneratedRecipesListPage> createState() => _GeneratedRecipesListPageState();
}

class _GeneratedRecipesListPageState extends State<GeneratedRecipesListPage> {
  final _supabase = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> _recipesStream() {
    return _supabase.from('ai_generated_recipes').stream(primaryKey: ['id']).order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generierte Rezepte')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _recipesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Fehler: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final recipes = snapshot.data!;
          if (recipes.isEmpty) {
            return const Center(child: Text('Keine gespeicherten Rezepte gefunden.'));
          }

          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final row = recipes[index];
              final dateStr = row['created_at'] as String?;
              final date = dateStr != null ? DateTime.parse(dateStr).toLocal() : DateTime.now();

              return ListTile(
                title: Text(row['name'] ?? 'Unbenannt'),
                subtitle: Text('${row['style']} • ${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  try {
                    final recipeData = row['recipe_data'];
                    if (recipeData != null) {
                      final recipe = AiRecipe.fromJson(Map<String, dynamic>.from(recipeData as Map));
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => RecipeCompletionPage(recipe: recipe)),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler beim Laden: $e')));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
