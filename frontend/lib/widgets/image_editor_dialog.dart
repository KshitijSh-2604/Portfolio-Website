import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'custom_crop.dart';

class ImageEditorDialog extends StatefulWidget {
  final Uint8List image;
  final String title;
  final bool isCircle;
  final double? aspectRatio;

  const ImageEditorDialog({
    super.key,
    required this.image,
    this.title = 'Edit Image',
    this.isCircle = false,
    this.aspectRatio,
  });

  @override
  State<ImageEditorDialog> createState() => _ImageEditorDialogState();
}

class _ImageEditorDialogState extends State<ImageEditorDialog> {
  final _controller = CustomCropController();
  late Uint8List _currentImage;
  bool _isCropping = false;
  int _rotationCount = 0;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.image;
  }

  void _rotateImage() {
    setState(() => _isCropping = true);
    final image = img.decodeImage(_currentImage);
    if (image != null) {
      final rotated = img.copyRotate(image, angle: 90);
      setState(() {
        _currentImage = Uint8List.fromList(img.encodeJpg(rotated, quality: 90));
        _rotationCount++;
        _isCropping = false;
      });
    } else {
      setState(() => _isCropping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0A14),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 1000),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Text(
                  'Pan image to move • Drag handles to resize',
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomCrop(
                        key: ValueKey('crop_key_$_rotationCount'),
                        image: _currentImage,
                        controller: _controller,
                        isCircle: widget.isCircle,
                        aspectRatio: widget.aspectRatio,
                      ),
                    ),
                  ),
                  // Zoom Controls Overlay
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_rounded, color: Colors.white70),
                            onPressed: _controller.zoomOut,
                            tooltip: 'Zoom Out',
                          ),
                          Container(width: 1, height: 20, color: Colors.white10),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                            onPressed: _controller.reset,
                            tooltip: 'Reset View',
                          ),
                          Container(width: 1, height: 20, color: Colors.white10),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, color: Colors.white70),
                            onPressed: _controller.zoomIn,
                            tooltip: 'Zoom In',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  icon: Icons.rotate_right_rounded,
                  label: 'Rotate',
                  onTap: _rotateImage,
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isCropping
                      ? null
                      : () async {
                          setState(() => _isCropping = true);
                          final cropped = await _controller.crop();
                          if (mounted) {
                            if (cropped != null) {
                              Navigator.pop(context, cropped);
                            } else {
                              setState(() => _isCropping = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to crop image')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 8,
                    shadowColor: const Color(0xFF7C4DFF).withOpacity(0.4),
                  ),
                  child: _isCropping
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: BorderSide(color: Colors.white.withOpacity(0.12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
