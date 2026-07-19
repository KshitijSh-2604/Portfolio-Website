import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';

class PostComposer extends StatefulWidget {
  final VoidCallback onClose;
  const PostComposer({super.key, required this.onClose});

  @override
  State<PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends State<PostComposer> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _linkController = TextEditingController();
  
  final List<String> _media = [];
  String? _externalLink;
  
  bool _submitting = false;
  bool _uploading = false;
  String? _error;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final _picker = ImagePicker();
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _videoUrlController.dispose();
    _linkController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _formatUrl(String url) {
    if (url.isEmpty) return url;
    String formatted = url.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'https://$formatted';
    }
    return formatted;
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _error = 'Content cannot be empty');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      final List<String> images = [];
      String? videoUrl;
      
      for (final m in _media) {
        final lower = m.toLowerCase();
        if (lower.contains('.mp4') || lower.contains('.mov') || lower.contains('video') || lower.contains('pexels')) {
          videoUrl = m;
        } else {
          images.add(m);
        }
      }

      await context.read<AppProvider>().createPost(
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        content: content,
        images: images,
        videoUrl: videoUrl,
        link: _externalLink,
      );
      widget.onClose();
    } catch (e) {
      setState(() { _submitting = false; _error = 'Failed to post: $e'; });
    }
  }

  Future<void> _pickMedia() async {
    if (_media.length >= 6) {
      _showAlert('Maximum 6 items allowed');
      return;
    }

    try {
      final List<XFile> pickedFiles = await _picker.pickMultipleMedia();
      
      if (pickedFiles.isEmpty) return;

      for (final file in pickedFiles) {
        if (_media.length >= 6) break;

        final bytes = await file.readAsBytes();
        final sizeMb = bytes.length / (1024 * 1024);

        if (sizeMb > 50) {
          _showAlert('File "${file.name}" exceeds 50MB limit.');
          continue;
        }

        setState(() { _uploading = true; _error = null; });
        final url = await _apiService.uploadImage(bytes, file.name);
        setState(() {
          _media.add(url);
        });
      }
      setState(() => _uploading = false);
    } catch (e) {
      setState(() { _uploading = false; _error = 'Upload failed: $e'; });
    }
  }

  void _addVideoUrl() {
    final url = _videoUrlController.text.trim();
    if (url.isEmpty) return;
    if (_media.length >= 6) {
      _showAlert('Maximum 6 items allowed');
      return;
    }
    setState(() {
      _media.add(_formatUrl(url));
      _videoUrlController.clear();
    });
  }

  void _setExternalLink() {
    final url = _linkController.text.trim();
    if (url.isEmpty) {
      setState(() => _externalLink = null);
      return;
    }
    setState(() {
      _externalLink = _formatUrl(url);
      _linkController.clear();
    });
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Limit Exceeded', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.read<AppProvider>().weather.accentColor;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111122),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 40)],
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('New Snapshot', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, color: Colors.white54), iconSize: 20),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(_titleController, 'Title (optional)'),
              const SizedBox(height: 12),
              _buildTextField(_contentController, "What's on your mind?", maxLines: 4),
              const SizedBox(height: 20),

              const Text('Media (Images & Videos - Max 6)', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _IconButton(
                    icon: Icons.add_photo_alternate_rounded,
                    onTap: _media.length < 6 ? _pickMedia : null,
                    loading: _uploading,
                    label: 'Gallery',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(_videoUrlController, 'Paste Video URL (Pexels, etc.)'),
                  ),
                  const SizedBox(width: 8),
                  _SmallButton(label: 'Add', onTap: _addVideoUrl),
                ],
              ),
              const SizedBox(height: 16),

              const Text('External Link', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildTextField(_linkController, 'Article or Repo URL')),
                  const SizedBox(width: 8),
                  _SmallButton(label: 'Set', onTap: _setExternalLink),
                ],
              ),
              if (_externalLink != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link_rounded, color: accent, size: 14),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _externalLink!,
                            style: TextStyle(color: accent, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _externalLink = null),
                          child: Icon(Icons.close, color: accent.withOpacity(0.5), size: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              if (_media.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _media.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _MediaThumb(
                      url: _media[i],
                      onRemove: () => setState(() => _media.removeAt(i)),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFFF5555), fontSize: 13)),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_submitting || _uploading) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Publish', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  final String label;

  const _IconButton({required this.icon, this.onTap, required this.loading, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
          child: loading 
            ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            : Icon(icon, color: onTap == null ? Colors.white24 : Colors.white70, size: 20),
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SmallButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;
  const _MediaThumb({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final lower = url.toLowerCase();
    final isVideo = lower.contains('.mp4') || lower.contains('.mov') || lower.contains('video') || lower.contains('pexels');
    
    return Stack(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isVideo 
              ? const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 30))
              : Image.network(url, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 2, right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
