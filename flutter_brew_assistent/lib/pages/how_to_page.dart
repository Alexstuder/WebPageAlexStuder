import 'package:flutter/material.dart';
import '../models/how_to_topic.dart';
import '../services/how_to_service.dart';

class HowToPage extends StatefulWidget {
  const HowToPage({super.key});

  @override
  State<HowToPage> createState() => _HowToPageState();
}

class _HowToPageState extends State<HowToPage> {
  final HowToService _howToService = HowToService();
  List<HowToTopic> _topics = [];
  int _selectedIndex = 0;
  bool _isLoading = true;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _profileId = 'self_hosted_profile'; // In real app, get from auth/service

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final topics = await _howToService.loadTopics(_profileId);
      setState(() {
        _topics = topics;
        if (_topics.isNotEmpty) {
          _updateEditorFields();
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _updateEditorFields() {
    if (_selectedIndex >= 0 && _selectedIndex < _topics.length) {
      _titleController.text = _topics[_selectedIndex].title;
      _contentController.text = _topics[_selectedIndex].content;
    }
  }

  Future<void> _saveCurrentTopic() async {
    if (_selectedIndex < 0 || _selectedIndex >= _topics.length) return;

    final topic = _topics[_selectedIndex];
    final updated = topic.copyWith(
      title: _titleController.text,
      content: _contentController.text,
    );

    try {
      final saved = await _howToService.saveTopic(updated);
      setState(() {
        _topics[_selectedIndex] = saved;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gespeichert'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    }
  }

  Future<void> _addTopic() async {
    final newTopic = HowToTopic.create(
      userProfileId: _profileId,
      title: 'Neues Thema',
      position: _topics.length,
    );

    try {
      final saved = await _howToService.saveTopic(newTopic);
      setState(() {
        _topics.add(saved);
        _selectedIndex = _topics.length - 1;
        _updateEditorFields();
      });
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Hinzufügen: $e')),
        );
      }
    }
  }

  Future<void> _deleteTopic() async {
    if (_selectedIndex < 0 || _selectedIndex >= _topics.length) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Löschen?'),
        content: const Text('Möchtest du dieses Thema wirklich löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen', style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm != true) return;

    try {
      await _howToService.deleteTopic(_topics[_selectedIndex].id);
      setState(() {
        _topics.removeAt(_selectedIndex);
        if (_selectedIndex >= _topics.length) {
          _selectedIndex = _topics.length - 1;
        }
        if (_topics.isNotEmpty) {
          _updateEditorFields();
        }
      });
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Löschen: $e')),
        );
      }
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _topics.removeAt(oldIndex);
      _topics.insert(newIndex, item);
      
      // Update selected index if it moved
      if (_selectedIndex == oldIndex) {
        _selectedIndex = newIndex;
      } else if (oldIndex < _selectedIndex && newIndex >= _selectedIndex) {
        _selectedIndex--;
      } else if (oldIndex > _selectedIndex && newIndex <= _selectedIndex) {
        _selectedIndex++;
      }
    });
    
    _howToService.updatePositions(_topics);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How To\'s'),
        actions: [
          if (_topics.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveCurrentTopic,
              tooltip: 'Aktuelles Thema speichern',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Index (Sidebar)
                Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128),
                    border: Border(
                      right: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ReorderableListView.builder(
                          itemCount: _topics.length,
                          onReorder: _onReorder,
                          itemBuilder: (context, index) {
                            final topic = _topics[index];
                            final isSelected = _selectedIndex == index;
                            return ListTile(
                              key: ValueKey(topic.id),
                              title: Text(
                                topic.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                ),
                              ),
                              selected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                  _updateEditorFields();
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          onPressed: _addTopic,
                          icon: const Icon(Icons.add),
                          label: const Text('Neues Thema'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 45),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Editor area
                Expanded(
                  child: _topics.isEmpty
                      ? const Center(child: Text('Erstelle ein neues Thema oder wähle eines aus.'))
                      : Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _titleController,
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      decoration: const InputDecoration(
                                        hintText: 'Titel...',
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: _deleteTopic,
                                    tooltip: 'Thema löschen',
                                  ),
                                ],
                              ),
                              const Divider(),
                              const SizedBox(height: 16),
                              Expanded(
                                child: TextField(
                                  controller: _contentController,
                                  maxLines: null,
                                  expands: true,
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: const InputDecoration(
                                    hintText: 'Inhalt schreiben...',
                                    border: InputBorder.none,
                                  ),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
