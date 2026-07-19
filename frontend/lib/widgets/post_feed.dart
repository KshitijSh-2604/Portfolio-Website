import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../utils/auth_manager.dart';
import '../services/api_service.dart';
import '../models/weather_model.dart';
import 'post_card.dart';
import 'post_composer.dart';

class PostFeed extends StatefulWidget {
  const PostFeed({super.key});

  @override
  State<PostFeed> createState() => _PostFeedState();
}

class _PostFeedState extends State<PostFeed> with SingleTickerProviderStateMixin {
  bool _showComposer = false;
  bool _isOwner = false;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fabController.forward();
    _isOwner = AuthManager.isOwner;
  }

  void _toggleComposer() {
    if (!_isOwner) {
      _showLoginDialog();
    } else {
      setState(() => _showComposer = !_showComposer);
    }
  }

  void _logout() {
    AuthManager.logout();
    setState(() { _isOwner = false; _showComposer = false; });
  }

  Future<void> _showLoginDialog() async {
    final ctrl = TextEditingController();
    final api = ApiService();

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) {
        bool loading = false;
        String? error;
        return StatefulBuilder(
          builder: (ctx, setDlg) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF111122),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.7), blurRadius: 40)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B61FF).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF7B61FF), size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text('Owner Access', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: ctrl,
                    obscureText: true,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onSubmitted: (_) => _doLogin(ctx, ctrl, api, setDlg, (v) => loading = v, (v) => error = v),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF7B61FF)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: Color(0xFFFF5555), fontSize: 12)),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(foregroundColor: Colors.white38),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : () => _doLogin(ctx, ctrl, api, setDlg, (v) => loading = v, (v) => error = v),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B61FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: loading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Unlock', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _doLogin(
    BuildContext ctx,
    TextEditingController ctrl,
    ApiService api,
    StateSetter setDlg,
    void Function(bool) setLoading,
    void Function(String?) setError,
  ) async {
    setDlg(() { setLoading(true); setError(null); });
    try {
      final token = await api.login(ctrl.text.trim());
      AuthManager.setToken(token);
      
      // Update owner location after login
      try {
        await api.updateOwnerLocation();
        if (ctx.mounted) {
          final provider = Provider.of<AppProvider>(ctx, listen: false);
          await provider.fetchWeather();
          await provider.fetchPortfolio();
        }
      } catch (e) {
        print("Failed to update location: $e");
      }

      if (ctx.mounted) Navigator.pop(ctx);
      setState(() { _isOwner = true; _showComposer = true; });
    } catch (_) {
      setDlg(() { setLoading(false); setError('Incorrect password'); });
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sync owner status with storage on every build
    _isOwner = AuthManager.isOwner;

    return Consumer<AppProvider>(builder: (ctx, provider, _) {
      final weather = provider.weather;
      final accent = weather.accentColor;

      return Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: weather.primaryTextColor.withOpacity(0.05))),
        ),
        child: Column(
          children: [
            _buildFeedHeader(provider, accent, weather),
            // Spotify now-playing pinned above the scrollable list
            _buildSpotifySection(provider, accent, weather),
            // Scrollable posts list (including composer)
            Expanded(
              child: _buildFeedList(provider, accent, weather),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFeedHeader(AppProvider provider, Color accent, WeatherModel weather) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: weather.primaryTextColor.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Life Snapshots', style: TextStyle(color: weather.primaryTextColor, fontSize: 18, fontWeight: FontWeight.w800)),
              Text(
                '${provider.posts.length} posts',
                style: TextStyle(color: weather.secondaryTextColor, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          // Logout button (only visible when owner is logged in)
          if (_isOwner) ...[
            Tooltip(
              message: 'Lock (logout)',
              child: GestureDetector(
                onTap: _logout,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: weather.glassColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: weather.glassBorderColor),
                  ),
                  child: Icon(Icons.lock_open_rounded, color: weather.secondaryTextColor, size: 15),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Compose / Lock button
          ScaleTransition(
            scale: CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
            child: GestureDetector(
              onTap: _toggleComposer,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _isOwner
                      ? (_showComposer ? accent.withOpacity(0.3) : accent)
                      : weather.glassColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isOwner ? [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 10)] : [],
                  border: _isOwner ? null : Border.all(color: weather.glassBorderColor),
                ),
                child: Icon(
                  _isOwner
                      ? (_showComposer ? Icons.close : Icons.edit_outlined)
                      : Icons.lock_outline_rounded,
                  color: _isOwner ? weather.onAccentColor : weather.secondaryTextColor,
                  size: 17,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotifySection(AppProvider provider, Color accent, WeatherModel weather) {
    final spotify = provider.spotify;
    final hasTrack = spotify.trackName != null && spotify.trackName!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: weather.isLightBackground ? Colors.black.withOpacity(0.04) : Colors.black.withOpacity(0.22),
        border: Border(
          bottom: BorderSide(
            color: spotify.isPlaying
                ? const Color(0xFF1DB954).withOpacity(0.2)
                : weather.primaryTextColor.withOpacity(0.04),
          ),
        ),
      ),
      child: hasTrack ? _buildNowPlaying(provider, spotify, weather) : _buildConnectSpotify(provider, weather),
    );
  }

  String _formatDuration(int? ms) {
    if (ms == null) return '0:00';
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildNowPlaying(AppProvider provider, dynamic spotify, WeatherModel weather) {
    final bool isPlaying = spotify.isPlaying;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Large Album Art at the start
        if (spotify.albumArt != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: spotify.albumArt!,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _albumPlaceholder(weather, size: 54),
            ),
          )
        else
          _albumPlaceholder(weather, size: 54),
        const SizedBox(width: 16),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      spotify.trackName ?? '',
                      style: TextStyle(
                        color: weather.primaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPlaying 
                        ? const Color(0xFF1DB954).withOpacity(0.12)
                        : weather.tertiaryTextColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isPlaying ? 'NOW PLAYING' : 'PAUSED',
                      style: TextStyle(
                        color: isPlaying ? const Color(0xFF1DB954) : weather.tertiaryTextColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                spotify.artistName ?? '',
                style: TextStyle(
                  color: weather.secondaryTextColor.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _formatDuration(spotify.progressMs),
                    style: TextStyle(color: weather.tertiaryTextColor, fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: spotify.progressFraction,
                        backgroundColor: weather.primaryTextColor.withOpacity(0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                        minHeight: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(spotify.durationMs),
                    style: TextStyle(color: weather.tertiaryTextColor, fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        if (spotify.trackUrl != null) ...[
          const SizedBox(width: 12),
          Column(
            children: [
              _WaveBars(isPlaying: isPlaying),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(spotify.trackUrl!)),
                child: Icon(Icons.open_in_new_rounded, color: weather.tertiaryTextColor, size: 16),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildConnectSpotify(AppProvider provider, WeatherModel weather) {
    return Row(
      children: [
        _albumPlaceholder(weather, size: 54),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spotify',
              style: TextStyle(color: weather.primaryTextColor, fontSize: 13, fontWeight: FontWeight.w700),
            ),
            Text(
              'Currently Inactive',
              style: TextStyle(color: weather.tertiaryTextColor, fontSize: 11),
            ),
          ],
        ),
        const Spacer(),
        if (_isOwner)
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.parse(provider.spotifyAuthUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Connect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          )
        else
          Icon(Icons.lock_outline_rounded, color: weather.tertiaryTextColor.withOpacity(0.3), size: 14),
      ],
    );
  }

  Widget _albumPlaceholder(WeatherModel weather, {double size = 36}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: weather.glassColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: weather.glassBorderColor),
      ),
      child: Icon(Icons.music_note, color: const Color(0xFF1DB954).withOpacity(0.5), size: size * 0.5),
    );
  }

  Widget _buildFeedList(AppProvider provider, Color accent, WeatherModel weather) {
    if (provider.postsLoading) {
      return Center(child: CircularProgressIndicator(color: accent, strokeWidth: 2));
    }

    final hasComposer = _showComposer && _isOwner;
    final hasError = provider.postsError != null;
    final isEmpty = provider.posts.isEmpty && !hasError;

    return RefreshIndicator(
      onRefresh: provider.fetchPosts,
      color: accent,
      backgroundColor: weather.isLightBackground ? Colors.white : const Color(0xFF111122),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        itemCount: 1 + (hasComposer ? 1 : 0) + (hasError ? 1 : isEmpty ? 1 : provider.posts.length),
        itemBuilder: (_, i) {
          int index = 0;

          // Optional Composer
          if (hasComposer) {
            if (i == index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PostComposer(onClose: () => setState(() => _showComposer = false)),
              );
            }
            index++;
          }

          // Error State
          if (hasError) {
            if (i == index) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: weather.tertiaryTextColor, size: 40),
                      const SizedBox(height: 12),
                      Text('Failed to load posts', style: TextStyle(color: weather.tertiaryTextColor, fontSize: 13)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: provider.fetchPosts, child: Text('Retry', style: TextStyle(color: accent))),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          // Empty State
          if (isEmpty) {
            if (i == index) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.collections_bookmark_outlined, color: weather.tertiaryTextColor.withOpacity(0.5), size: 48),
                      const SizedBox(height: 16),
                      Text('No snapshots yet', style: TextStyle(color: weather.tertiaryTextColor, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(
                        _isOwner ? 'Tap the pencil above to add one' : 'Nothing here yet',
                        style: TextStyle(color: weather.tertiaryTextColor.withOpacity(0.6), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          // Actual Posts
          final postIndex = i - index;
          if (postIndex < 0 || postIndex >= provider.posts.length) return const SizedBox.shrink();
          
          final post = provider.posts[postIndex];

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 600 + postIndex * 150),
            curve: Curves.easeOutExpo,
            builder: (_, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, 40 * (1 - v)),
                child: child,
              ),
            ),
            child: PostCard(
              post: post,
              accentColor: accent,
              canDelete: _isOwner,
            ),
          );
        },
      ),
    );
  }
}

class _WaveBars extends StatefulWidget {
  final bool isPlaying;
  const _WaveBars({required this.isPlaying});

  @override
  State<_WaveBars> createState() => _WaveBarsState();
}

class _WaveBarsState extends State<_WaveBars> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    if (widget.isPlaying) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_WaveBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          children: List.generate(3, (i) {
            final height = 4.0 + (i == 1 ? 6.0 : 3.0) * _ctrl.value;
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
