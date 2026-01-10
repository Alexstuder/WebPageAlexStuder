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
  int _selectedPageIndex = 0;
  bool _isLoading = true;
  
  final _topicTitleController = TextEditingController();
  final _pageTitleController = TextEditingController();
  final _pageContentController = TextEditingController();
  
  double _sidebarWidth = 250.0;
  final _profileId = 'self_hosted_profile';

  @override
  void initState() {
    super.initState();
    _loadData();

    _topicTitleController.addListener(_onTopicTitleChanged);
    _pageTitleController.addListener(_onPageTitleChanged);
    _pageContentController.addListener(_onPageContentChanged);
  }

  @override
  void dispose() {
    _topicTitleController.dispose();
    _pageTitleController.dispose();
    _pageContentController.dispose();
    super.dispose();
  }

  // To avoid constant state rebuilds and cursor jumps, we update the local model silently
  void _onTopicTitleChanged() {
    if (_selectedIndex >= 0 && _selectedIndex < _topics.length) {
      final val = _topicTitleController.text;
      if (_topics[_selectedIndex].title != val) {
        setState(() {
          _topics[_selectedIndex] = _topics[_selectedIndex].copyWith(title: val);
        });
      }
    }
  }

  void _onPageTitleChanged() {
    if (_selectedIndex >= 0 && _selectedIndex < _topics.length) {
      final topic = _topics[_selectedIndex];
      if (_selectedPageIndex >= 0 && _selectedPageIndex < topic.pages.length) {
        final val = _pageTitleController.text;
        if (topic.pages[_selectedPageIndex].title != val) {
          setState(() {
            final newPages = List<HowToPageData>.from(topic.pages);
            newPages[_selectedPageIndex] = newPages[_selectedPageIndex].copyWith(title: val);
            _topics[_selectedIndex] = topic.copyWith(pages: newPages);
          });
        }
      }
    }
  }

  void _onPageContentChanged() {
    if (_selectedIndex >= 0 && _selectedIndex < _topics.length) {
      final topic = _topics[_selectedIndex];
      if (_selectedPageIndex >= 0 && _selectedPageIndex < topic.pages.length) {
        final val = _pageContentController.text;
        if (topic.pages[_selectedPageIndex].content != val) {
          setState(() {
            final newPages = List<HowToPageData>.from(topic.pages);
            newPages[_selectedPageIndex] = newPages[_selectedPageIndex].copyWith(content: val);
            _topics[_selectedIndex] = topic.copyWith(pages: newPages);
          });
        }
      }
    }
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
      final topic = _topics[_selectedIndex];
      _topicTitleController.text = topic.title;
      
      if (topic.pages.isNotEmpty) {
        if (_selectedPageIndex >= topic.pages.length) {
          _selectedPageIndex = 0;
        }
        _pageTitleController.text = topic.pages[_selectedPageIndex].title;
        _pageContentController.text = topic.pages[_selectedPageIndex].content;
      } else {
        _pageTitleController.text = '';
        _pageContentController.text = '';
      }
    }
  }

  Future<void> _saveCurrentTopic() async {
    if (_selectedIndex < 0 || _selectedIndex >= _topics.length) return;

    final topic = _topics[_selectedIndex];
    try {
      final saved = await _howToService.saveTopic(topic);
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
      pages: [HowToPageData.create(title: 'Seite 1')],
      position: _topics.length,
    );

    try {
      final saved = await _howToService.saveTopic(newTopic);
      setState(() {
        _topics.add(saved);
        _selectedIndex = _topics.length - 1;
        _selectedPageIndex = 0;
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
        if (_topics.isEmpty) {
          _selectedIndex = 0;
        } else if (_selectedIndex >= _topics.length) {
          _selectedIndex = _topics.length - 1;
        }
        _selectedPageIndex = 0;
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

  void _onReorderTopics(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _topics.removeAt(oldIndex);
      _topics.insert(newIndex, item);
      
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

  void _addPage() {
    if (_selectedIndex < 0 || _selectedIndex >= _topics.length) return;
    final topic = _topics[_selectedIndex];
    final newPage = HowToPageData.create(title: 'Neue Seite');
    setState(() {
      final newPages = List<HowToPageData>.from(topic.pages)..add(newPage);
      _topics[_selectedIndex] = topic.copyWith(pages: newPages);
      _selectedPageIndex = newPages.length - 1;
      _updateEditorFields();
    });
  }

  void _deletePage(int pageIndex) {
    if (_selectedIndex < 0 || _selectedIndex >= _topics.length) return;
    final topic = _topics[_selectedIndex];
    if (topic.pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Das Thema muss mindestens eine Seite haben.')),
      );
      return;
    }

    setState(() {
      final newPages = List<HowToPageData>.from(topic.pages)..removeAt(pageIndex);
      _topics[_selectedIndex] = topic.copyWith(pages: newPages);
      if (_selectedPageIndex >= newPages.length) {
        _selectedPageIndex = newPages.length - 1;
      }
      _updateEditorFields();
    });
  }

  void _onReorderPages(int oldIndex, int newIndex) {
    if (_selectedIndex < 0 || _selectedIndex >= _topics.length) return;
    final topic = _topics[_selectedIndex];
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final newPages = List<HowToPageData>.from(topic.pages);
      final item = newPages.removeAt(oldIndex);
      newPages.insert(newIndex, item);
      _topics[_selectedIndex] = topic.copyWith(pages: newPages);
      
      if (_selectedPageIndex == oldIndex) {
        _selectedPageIndex = newIndex;
      } else if (oldIndex < _selectedPageIndex && newIndex >= _selectedPageIndex) {
        _selectedPageIndex--;
      } else if (oldIndex > _selectedPageIndex && newIndex <= _selectedPageIndex) {
        _selectedPageIndex++;
      }
    });
  }

  void _showTabContextMenu(BuildContext context, Offset position, int pageIndex) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Seite löschen'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'delete') {
        _deletePage(pageIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topic = _topics.isNotEmpty && _selectedIndex < _topics.length ? _topics[_selectedIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('How To\'s'),
        actions: [
          if (_topics.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveCurrentTopic,
              tooltip: 'Speichern',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Index (Sidebar)
                SizedBox(
                  width: _sidebarWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128),
                      border: Border(
                        right: BorderSide(color: Theme.of(context).dividerColor.withAlpha(50)),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ReorderableListView.builder(
                            itemCount: _topics.length,
                            onReorder: _onReorderTopics,
                            itemBuilder: (context, index) {
                              final t = _topics[index];
                              final isSelected = _selectedIndex == index;
                              return ListTile(
                                key: ValueKey(t.id),
                                title: Text(
                                  t.title,
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
                                    _selectedPageIndex = 0;
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
                ),
                // Resizer Handle
                GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _sidebarWidth += details.delta.dx;
                      if (_sidebarWidth < 150) _sidebarWidth = 150;
                      if (_sidebarWidth > 600) _sidebarWidth = 600;
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: Container(
                      width: 4,
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          width: 1,
                          color: Theme.of(context).dividerColor.withAlpha(80),
                        ),
                      ),
                    ),
                  ),
                ),
                // Main Content
                Expanded(
                  child: topic == null
                      ? const Center(child: Text('Erstelle ein neues Thema oder wähle eines aus.'))
                      : Column(
                          children: [
                            // Topic Title (Sidebar Title)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: TextField(
                                controller: _topicTitleController,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                                decoration: const InputDecoration(
                                  hintText: 'Themen-Titel (Sidebar)...',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            // Tab Bar
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                border: Border(
                                  bottom: BorderSide(color: Theme.of(context).dividerColor.withAlpha(50)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ReorderableListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: topic.pages.length,
                                      onReorder: _onReorderPages,
                                      proxyDecorator: (child, index, animation) {
                                        return Material(
                                          elevation: 4,
                                          color: Colors.transparent,
                                          child: child,
                                        );
                                      },
                                      itemBuilder: (context, index) {
                                        final page = topic.pages[index];
                                        final isSelected = _selectedPageIndex == index;
                                        return GestureDetector(
                                          key: ValueKey(page.id),
                                          onTap: () {
                                            setState(() {
                                              _selectedPageIndex = index;
                                              _updateEditorFields();
                                            });
                                          },
                                          onSecondaryTapDown: (details) => _showTabContextMenu(context, details.globalPosition, index),
                                          child: Container(
                                            margin: const EdgeInsets.only(right: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 20),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                                  width: 2,
                                                ),
                                              ),
                                              color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withAlpha(50) : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              page.title.isEmpty ? 'Seite ${index + 1}' : page.title,
                                              style: TextStyle(
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: _addPage,
                                    tooltip: 'Neue Seite hinzufügen',
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                            // Editor Area
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _pageTitleController,
                                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            decoration: const InputDecoration(
                                              hintText: 'Seitentitel...',
                                              border: InputBorder.none,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: _deleteTopic,
                                          tooltip: 'Ganzes Thema löschen',
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: TextField(
                                        controller: _pageContentController,
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
                ),
              ],
            ),
    );
  }
}
