import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:image/image.dart' as img;

class ImageEditorDialog extends StatefulWidget {
  final Uint8List image;
  final String title;

  const ImageEditorDialog({super.key, required this.image, this.title = 'Edit Image'});

  @override
  State<ImageEditorDialog> createState() => _ImageEditorDialogState();
}

class _ImageEditorDialogState extends State<ImageEditorDialog> {
  final _controller = CropController();
  late Uint8List _currentImage;
  bool _isCropping = false;
  int _rotationCount = 0;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.image;
  }

  void _rotateImage() {
    setState(() => _isCropping = true); // Use as temporary loading state
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: 1000,
        height: 900,
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
                  'Zoom & Pan Image • Drag Handles to Resize',
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Crop(
                    key: ValueKey('crop_key_$_rotationCount'),
                    image: _currentImage,
                    controller: _controller,
                    onCropped: (image) {
                      Navigator.pop(context, image);
                    },
                    aspectRatio: 1,
                    withCircleUi: true,
                    interactive: true,
                    fixCropRect: false,
                    initialSize: 0.5, // Start with 50% size to allow more room for movement/zoom
                    baseColor: Colors.black,
                    maskColor: Colors.black.withOpacity(0.8),
                    radius: 20,
                    cornerDotBuilder: (size, edgeAlignment) => Container(
                      width: size * 1.2,
                      height: size * 1.2,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C4DFF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
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
                      : () {
                          setState(() => _isCropping = true);
                          _controller.crop();
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
