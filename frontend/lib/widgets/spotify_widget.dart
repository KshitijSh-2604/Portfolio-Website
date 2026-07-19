import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_provider.dart';
import '../models/weather_model.dart';

class SpotifyWidget extends StatefulWidget {
  const SpotifyWidget({super.key});

  @override
  State<SpotifyWidget> createState() => _SpotifyWidgetState();
}

class _SpotifyWidgetState extends State<SpotifyWidget> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, provider, _) {
      final spotify = provider.spotify;
      final accent = provider.weather.accentColor;

      if (!spotify.isPlaying || spotify.trackName == null) {
        return _buildConnectButton(context, provider, accent);
      }

      return _buildNowPlaying(context, provider, accent);
    });
  }

  Widget _buildConnectButton(BuildContext context, AppProvider provider, Color accent) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(provider.spotifyAuthUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.4)),
          boxShadow: [BoxShadow(color: const Color(0xFF1DB954).withOpacity(0.1), blurRadius: 12)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_note, color: Color(0xFF1DB954), size: 16),
            const SizedBox(width: 8),
            Text(
              'Connect Spotify',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNowPlaying(BuildContext context, AppProvider provider, Color accent) {
    final spotify = provider.spotify;
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1DB954).withOpacity(0.08), blurRadius: 20),
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildWaveBars(),
              const SizedBox(width: 8),
              Text(
                'NOW PLAYING',
                style: TextStyle(
                  color: const Color(0xFF1DB954).withOpacity(0.9),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (spotify.albumArt != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: spotify.albumArt!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _albumPlaceholder(),
                  ),
                )
              else
                _albumPlaceholder(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (spotify.trackUrl != null) {
                          await launchUrl(Uri.parse(spotify.trackUrl!), mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Text(
                        spotify.trackName ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spotify.artistName ?? '',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (spotify.durationMs != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: spotify.progressFraction,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                minHeight: 3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _albumPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.music_note, color: Color(0xFF1DB954), size: 24),
    );
  }

  Widget _buildWaveBars() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (_, __) {
        return Row(
          children: List.generate(3, (i) {
            final height = 4.0 + (i == 1 ? 6.0 : 3.0) * _waveController.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                width: 2,
                height: height,
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
