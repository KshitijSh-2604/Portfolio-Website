class SpotifyTrackModel {
  final bool isPlaying;
  final bool isLinked;
  final String? trackName;
  final String? artistName;
  final String? albumName;
  final String? albumArt;
  final String? trackUrl;
  final int? progressMs;
  final int? durationMs;

  SpotifyTrackModel({
    required this.isPlaying,
    this.isLinked = false,
    this.trackName,
    this.artistName,
    this.albumName,
    this.albumArt,
    this.trackUrl,
    this.progressMs,
    this.durationMs,
  });

  factory SpotifyTrackModel.fromJson(Map<String, dynamic> json) {
    return SpotifyTrackModel(
      isPlaying: json['isPlaying'] as bool? ?? false,
      isLinked: json['isLinked'] as bool? ?? false,
      trackName: json['trackName'] as String?,
      artistName: json['artistName'] as String?,
      albumName: json['albumName'] as String?,
      albumArt: json['albumArt'] as String?,
      trackUrl: json['trackUrl'] as String?,
      progressMs: json['progressMs'] as int?,
      durationMs: json['durationMs'] as int?,
    );
  }

  double get progressFraction {
    if (progressMs == null || durationMs == null || durationMs == 0) return 0;
    return progressMs! / durationMs!;
  }
}
