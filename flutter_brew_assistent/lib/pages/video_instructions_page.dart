import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/video_instruction.dart';
import '../services/video_instruction_service.dart';

class VideoInstructionsPage extends StatefulWidget {
  final String profileId;
  const VideoInstructionsPage({super.key, required this.profileId});

  @override
  State<VideoInstructionsPage> createState() => _VideoInstructionsPageState();
}

class _VideoInstructionsPageState extends State<VideoInstructionsPage> {
  final _service = VideoInstructionService();
  List<VideoInstruction> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    final videos = await _service.fetchVideos(widget.profileId);
    setState(() {
      _videos = videos;
      _isLoading = false;
    });
  }

  String? _getVideoId(String url) {
    if (url.contains('v=')) {
      return url.split('v=')[1].split('&')[0];
    } else if (url.contains('youtu.be/')) {
      return url.split('youtu.be/')[1].split('?')[0];
    }
    return null;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  void _showAddVideoDialog({VideoInstruction? existingVideo}) {
    final titleController = TextEditingController(text: existingVideo?.title);
    final urlController = TextEditingController(text: existingVideo?.youtubeUrl);
    final descController = TextEditingController(text: existingVideo?.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingVideo == null ? 'Video hinzufügen' : 'Video bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Titel'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'YouTube URL'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Beschreibung (optional)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () async {
              final video = VideoInstruction(
                id: existingVideo?.id ?? const Uuid().v4(),
                userProfileId: widget.profileId,
                title: titleController.text,
                youtubeUrl: urlController.text,
                description: descController.text,
                position: existingVideo?.position ?? _videos.length,
                createdAt: existingVideo?.createdAt ?? DateTime.now(),
              );
              await _service.saveVideo(video);
              if (context.mounted) Navigator.pop(context);
              _loadVideos();
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Anleitungen'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Noch keine Videos gespeichert.'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddVideoDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Erstes Video hinzufügen'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    final videoId = _getVideoId(video.youtubeUrl);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _launchUrl(video.youtubeUrl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (videoId != null)
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.network(
                                    'https://img.youtube.com/vi/$videoId/0.jpg',
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 200,
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.video_library, size: 50),
                                    ),
                                  ),
                                  const Icon(Icons.play_circle_fill, size: 60, color: Colors.white70),
                                ],
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          video.title,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () => _showAddVideoDialog(existingVideo: video),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Video löschen?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
                                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await _service.deleteVideo(video.id);
                                            _loadVideos();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  if (video.description != null && video.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        video.description!,
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVideoDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
