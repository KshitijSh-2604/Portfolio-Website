import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MediaViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const MediaViewer({super.key, required this.urls, this.initialIndex = 0});

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex < widget.urls.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _next();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _prev();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.95),
        body: Stack(
          children: [
            // Background closer
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black),
            ),
            
            // Content
            PageView.builder(
              itemCount: widget.urls.length,
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final url = widget.urls[index];
                final isVideo = url.contains('.mp4') || url.contains('.mov') || url.contains('video');
                
                return Center(
                  child: isVideo 
                    ? _VideoPlayer(url: url)
                    : InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const CircularProgressIndicator(color: Colors.white24),
                          errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white24, size: 50),
                        ),
                      ),
                );
              },
            ),

            // UI Overlays
            Positioned(
              top: 40,
              left: 20,
              child: Text(
                '${_currentIndex + 1} / ${widget.urls.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Navigation Arrows (Desktop)
            if (_currentIndex > 0)
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 40),
                    onPressed: _prev,
                  ),
                ),
              ),
            if (_currentIndex < widget.urls.length - 1)
              Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 40),
                    onPressed: _next,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayer extends StatefulWidget {
  final String url;
  const _VideoPlayer({required this.url});

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _videoController.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: true,
          aspectRatio: _videoController.value.aspectRatio,
          allowFullScreen: false,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.white,
            handleColor: Colors.white,
            backgroundColor: Colors.white24,
            bufferedColor: Colors.white12,
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: Chewie(controller: _chewieController!),
        ),
      );
    }
    return const CircularProgressIndicator(color: Colors.white24);
  }
}
