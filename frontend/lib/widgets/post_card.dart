import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/app_provider.dart';
import '../models/weather_model.dart';
import 'media_viewer.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final Color accentColor;
  final bool canDelete;

  const PostCard({super.key, required this.post, required this.accentColor, this.canDelete = false});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _hovering = false;
  bool _showDeleteConfirm = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _openViewer(BuildContext context, int index) {
    final mediaUrls = [...widget.post.images];
    if (widget.post.videoUrl != null) mediaUrls.add(widget.post.videoUrl!);
    
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => MediaViewer(urls: mediaUrls, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<AppProvider>().weather;

    return MouseRegion(
      onEnter: (_) { setState(() => _hovering = true); _hoverController.forward(); },
      onExit: (_) { setState(() => _hovering = false); _hoverController.reverse(); },
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (_, child) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Color.lerp(
                weather.glassColor,
                weather.primaryTextColor.withOpacity(0.08),
                _hoverController.value,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color.lerp(
                  weather.glassBorderColor,
                  widget.accentColor.withOpacity(0.2),
                  _hoverController.value,
                )!,
              ),
              boxShadow: _hovering ? [BoxShadow(color: widget.accentColor.withOpacity(0.05), blurRadius: 20)] : [],
            ),
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(weather),
              const SizedBox(height: 10),
              if (widget.post.title != null) ...[
                Text(
                  widget.post.title!,
                  style: TextStyle(color: weather.primaryTextColor, fontSize: 15, fontWeight: FontWeight.w600, height: 1.3),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                widget.post.content,
                style: TextStyle(color: weather.secondaryTextColor, fontSize: 13, height: 1.6),
              ),
              if (widget.post.images.isNotEmpty || widget.post.videoUrl != null) ...[
                const SizedBox(height: 12),
                _buildCollage(context, weather),
              ],
              if (widget.post.link != null) ...[
                const SizedBox(height: 12),
                _buildExternalLink(weather),
              ],
              if (widget.canDelete && _showDeleteConfirm) ...[
                const SizedBox(height: 12),
                _buildDeleteConfirm(weather),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WeatherModel weather) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.accentColor.withOpacity(0.5), width: 1.5),
          ),
          child: ClipOval(
            child: Image.network(
              'https://avatars.githubusercontent.com/u/55450150?v=4',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kshitij Sharma', style: TextStyle(color: weather.primaryTextColor, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(
              DateFormat('MMM dd, yyyy · hh:mm a').format(widget.post.createdAt.toLocal()),
              style: TextStyle(color: weather.tertiaryTextColor, fontSize: 10),
            ),
          ],
        ),
        const Spacer(),
        if (widget.canDelete && _hovering && !_showDeleteConfirm)
          IconButton(
            onPressed: () => setState(() => _showDeleteConfirm = true),
            icon: Icon(Icons.delete_outline, size: 16, color: weather.tertiaryTextColor),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildCollage(BuildContext context, WeatherModel weather) {
    final media = [...widget.post.images];
    if (widget.post.videoUrl != null) media.add(widget.post.videoUrl!);
    
    if (media.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: BoxConstraints(maxHeight: media.length > 4 ? 600 : 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildMediaGrid(context, media, weather),
      ),
    );
  }

  Widget _buildMediaGrid(BuildContext context, List<String> media, WeatherModel weather) {
    if (media.length == 1) {
      return _buildMediaItem(context, media[0], 0, weather);
    } else if (media.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildMediaItem(context, media[0], 0, weather)),
          const SizedBox(width: 4),
          Expanded(child: _buildMediaItem(context, media[1], 1, weather)),
        ],
      );
    } else if (media.length == 3) {
      return Row(
        children: [
          Expanded(flex: 2, child: _buildMediaItem(context, media[0], 0, weather)),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildMediaItem(context, media[1], 1, weather)),
                const SizedBox(height: 4),
                Expanded(child: _buildMediaItem(context, media[2], 2, weather)),
              ],
            ),
          ),
        ],
      );
    } else {
      // 4, 5, or 6 items -> 2 columns
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1.4,
        ),
        itemCount: media.length,
        itemBuilder: (context, index) => _buildMediaItem(context, media[index], index, weather),
      );
    }
  }

  Widget _buildMediaItem(BuildContext context, String url, int index, WeatherModel weather) {
    final lower = url.toLowerCase();
    final isVideo = lower.contains('.mp4') || lower.contains('.mov') || lower.contains('video') || lower.contains('pexels');
    
    return GestureDetector(
      onTap: () => _openViewer(context, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isVideo)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_fill, color: widget.accentColor.withOpacity(0.8), size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'VIDEO',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (_, __) => Container(color: weather.glassColor),
              errorWidget: (_, __, ___) => Container(
                color: weather.glassColor,
                child: const Icon(Icons.broken_image),
              ),
            ),
          if (isVideo)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExternalLink(WeatherModel weather) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(widget.post.link!)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: weather.glassColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: weather.glassBorderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_rounded, color: widget.accentColor, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.post.link!,
                style: TextStyle(color: widget.accentColor, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteConfirm(WeatherModel weather) {
    return Row(
      children: [
        Text('Delete this post?', style: TextStyle(color: weather.secondaryTextColor, fontSize: 12)),
        const Spacer(),
        TextButton(
          onPressed: () => setState(() => _showDeleteConfirm = false),
          child: Text('Cancel', style: TextStyle(color: weather.tertiaryTextColor, fontSize: 12)),
        ),
        const SizedBox(width: 4),
        ElevatedButton(
          onPressed: () async {
            await context.read<AppProvider>().deletePost(widget.post.id);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5252),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Delete', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
