import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class CustomCropController extends ChangeNotifier {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Rect _cropRect = Rect.zero;
  
  double get scale => _scale;
  Offset get offset => _offset;
  Rect get cropRect => _cropRect;

  // Callback to trigger crop
  Future<Uint8List?> Function()? _cropCallback;

  void zoomIn() {
    _scale = (_scale + 0.1).clamp(0.5, 5.0);
    notifyListeners();
  }

  void zoomOut() {
    _scale = (_scale - 0.1).clamp(0.5, 5.0);
    notifyListeners();
  }

  void reset() {
    _scale = 1.0;
    _offset = Offset.zero;
    notifyListeners();
  }

  Future<Uint8List?> crop() async {
    if (_cropCallback != null) {
      return await _cropCallback!();
    }
    return null;
  }
}

class CustomCrop extends StatefulWidget {
  final Uint8List image;
  final CustomCropController controller;
  final bool isCircle;
  final double? aspectRatio;

  const CustomCrop({
    super.key,
    required this.image,
    required this.controller,
    this.isCircle = false,
    this.aspectRatio,
  });

  @override
  State<CustomCrop> createState() => _CustomCropState();
}

class _CustomCropState extends State<CustomCrop> {
  ui.Image? _uiImage;
  bool _initialized = false;
  
  Size _viewSize = Size.zero;
  
  // Crop Rect in VIEWPORT PIXELS
  Rect _cropRect = Rect.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
    widget.controller.addListener(_onControllerChanged);
    widget.controller._cropCallback = _doCrop;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  Future<void> _loadImage() async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(widget.image, (ui.Image img) {
      completer.complete(img);
    });
    _uiImage = await completer.future;
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  Rect _calculateTransformedImageRect() {
    if (_uiImage == null || _viewSize == Size.zero) return Rect.zero;

    final double imgW = _uiImage!.width.toDouble();
    final double imgH = _uiImage!.height.toDouble();
    final double imgAspect = imgW / imgH;
    final double viewAspect = _viewSize.width / _viewSize.height;

    double baseW, baseH;
    if (imgAspect > viewAspect) {
      baseW = _viewSize.width;
      baseH = _viewSize.width / imgAspect;
    } else {
      baseH = _viewSize.height;
      baseW = _viewSize.height * imgAspect;
    }

    final double scale = widget.controller.scale;
    final Offset offset = widget.controller.offset;

    final double transformedW = baseW * scale;
    final double transformedH = baseH * scale;

    final Offset viewportCenter = Offset(_viewSize.width / 2, _viewSize.height / 2);
    final Offset transformedCenter = viewportCenter + offset;
    return Rect.fromCenter(
      center: transformedCenter,
      width: transformedW,
      height: transformedH,
    );
  }

  Future<Uint8List?> _doCrop() async {
    if (_uiImage == null || _cropRect == Rect.zero) return null;

    final double imgW = _uiImage!.width.toDouble();
    final double imgH = _uiImage!.height.toDouble();
    final Size imageSize = Size(imgW, imgH);

    // 1. Get the exact mapping used by BoxFit.contain
    final FittedSizes fitted = applyBoxFit(BoxFit.contain, imageSize, _viewSize);
    final Size baseDisplaySize = fitted.destination;
    
    // 2. Calculate the fully transformed image rectangle in viewport space
    // Account for center alignment, offset, and scale
    final double scale = widget.controller.scale;
    final Offset offset = widget.controller.offset;

    final double transformedW = baseDisplaySize.width * scale;
    final double transformedH = baseDisplaySize.height * scale;

    final Offset viewportCenter = Offset(_viewSize.width / 2, _viewSize.height / 2);
    final Offset transformedCenter = viewportCenter + offset;
    
    final Rect transformedImageRect = Rect.fromCenter(
      center: transformedCenter,
      width: transformedW,
      height: transformedH,
    );

    // 3. Map the viewport crop rectangle to the image's internal pixel space
    final double sourceX = ((_cropRect.left - transformedImageRect.left) / transformedImageRect.width) * imgW;
    final double sourceY = ((_cropRect.top - transformedImageRect.top) / transformedImageRect.height) * imgH;
    final double sourceW = (_cropRect.width / transformedImageRect.width) * imgW;
    final double sourceH = (_cropRect.height / transformedImageRect.height) * imgH;

    // 4. Perform the crop on a high-res canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = ui.FilterQuality.high;

    // Clamp to image boundaries
    final Rect srcRect = Rect.fromLTWH(
      sourceX.clamp(0.0, imgW),
      sourceY.clamp(0.0, imgH),
      sourceW.clamp(1.0, imgW - sourceX.clamp(0.0, imgW)),
      sourceH.clamp(1.0, imgH - sourceY.clamp(0.0, imgH)),
    );

    final int targetW = srcRect.width.toInt().clamp(1, 10000);
    final int targetH = srcRect.height.toInt().clamp(1, 10000);

    canvas.drawImageRect(
      _uiImage!,
      srcRect,
      Rect.fromLTWH(0, 0, srcRect.width, srcRect.height),
      paint,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(targetW, targetH);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Center(child: CircularProgressIndicator());

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_viewSize != constraints.biggest) {
          _viewSize = constraints.biggest;
          if (_cropRect == Rect.zero) {
            double initialW = _viewSize.width * 0.8;
            double initialH = _viewSize.height * 0.6;
            
            if (widget.aspectRatio != null) {
              if (initialW / initialH > widget.aspectRatio!) {
                initialW = initialH * widget.aspectRatio!;
              } else {
                initialH = initialW / widget.aspectRatio!;
              }
            } else if (widget.isCircle) {
              initialW = initialH = min(initialW, initialH);
            }

            _cropRect = Rect.fromCenter(
              center: Offset(_viewSize.width / 2, _viewSize.height / 2),
              width: initialW,
              height: initialH,
            );
          }
        }
        
        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              widget.controller._offset += details.delta;
            });
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRect(
                  child: Transform(
                    transform: Matrix4.identity()
                      ..translate(widget.controller.offset.dx, widget.controller.offset.dy)
                      ..scale(widget.controller.scale),
                    alignment: Alignment.center,
                    child: Image.memory(widget.image, fit: BoxFit.contain),
                  ),
                ),
              ),
              
              Positioned.fill(
                child: IgnorePointer(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.6),
                      BlendMode.srcOut,
                    ),
                    child: Stack(
                      children: [
                        Container(color: Colors.black),
                        Positioned.fromRect(
                          rect: _cropRect,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              _buildInteractiveCropBox(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInteractiveCropBox() {
    return Stack(
      children: [
        Positioned.fromRect(
          rect: _cropRect,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _cropRect = _cropRect.shift(details.delta);
                // Keep inside viewport
                double left = _cropRect.left.clamp(0, _viewSize.width - _cropRect.width);
                double top = _cropRect.top.clamp(0, _viewSize.height - _cropRect.height);
                _cropRect = Rect.fromLTWH(left, top, _cropRect.width, _cropRect.height);
              });
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF7C4DFF), width: 2),
                shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
              ),
            ),
          ),
        ),
        
        _buildHandle(_cropRect.topLeft, (d) => _resize(d, true, true)),
        _buildHandle(_cropRect.topRight, (d) => _resize(d, false, true)),
        _buildHandle(_cropRect.bottomLeft, (d) => _resize(d, true, false)),
        _buildHandle(_cropRect.bottomRight, (d) => _resize(d, false, false)),
      ],
    );
  }

  void _resize(Offset delta, bool left, bool top) {
    setState(() {
      double newLeft = _cropRect.left;
      double newTop = _cropRect.top;
      double newWidth = _cropRect.width;
      double newHeight = _cropRect.height;

      if (left) {
        newLeft = (_cropRect.left + delta.dx).clamp(0, _cropRect.right - 20);
        newWidth = _cropRect.right - newLeft;
      } else {
        newWidth = (_cropRect.width + delta.dx).clamp(20, _viewSize.width - _cropRect.left);
      }

      if (top) {
        newTop = (_cropRect.top + delta.dy).clamp(0, _cropRect.bottom - 20);
        newHeight = _cropRect.bottom - newTop;
      } else {
        newHeight = (_cropRect.height + delta.dy).clamp(20, _viewSize.height - _cropRect.top);
      }

      if (widget.aspectRatio != null) {
        // Force aspect ratio by adjusting the side that wasn't primarily dragged if possible, 
        // or just pick one to be dominant.
        if (delta.dx.abs() > delta.dy.abs()) {
          newHeight = newWidth / widget.aspectRatio!;
        } else {
          newWidth = newHeight * widget.aspectRatio!;
        }
      }

      _cropRect = Rect.fromLTWH(newLeft, newTop, newWidth, newHeight);
    });
  }

  Widget _buildHandle(Offset pos, Function(Offset) onDrag) {
    return Positioned(
      left: pos.dx - 15,
      top: pos.dy - 15,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta),
        child: Container(
          width: 30,
          height: 30,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
