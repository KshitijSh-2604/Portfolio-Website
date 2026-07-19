import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../models/weather_model.dart';
import '../models/spotify_model.dart';
import '../models/portfolio_model.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  PortfolioDataModel? _portfolio;
  WeatherModel _weather = WeatherModel(
    condition: WeatherCondition.clear,
    temperature: 32,
    feelsLike: 35,
    description: 'clear sky',
    icon: '01d',
    humidity: 45,
    windSpeed: 3.0,
  );
  SpotifyTrackModel _spotify = SpotifyTrackModel(isPlaying: false);
  List<PostModel> _posts = [];
  bool _postsLoading = true;
  bool _weatherLoading = true;
  String? _postsError;

  int _totalViews = 0;
  int _currentViewers = 1;
  WebSocketChannel? _wsChannel;

  Timer? _weatherTimer;
  Timer? _spotifyTimer;

  PortfolioDataModel? get portfolio => _portfolio;
  WeatherModel get weather => _weather;
  SpotifyTrackModel get spotify => _spotify;
  List<PostModel> get posts => _posts;
  bool get postsLoading => _postsLoading;
  bool get weatherLoading => _weatherLoading;
  String? get postsError => _postsError;
  int get totalViews => _totalViews;
  int get currentViewers => _currentViewers;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      fetchWeather(),
      _fetchSpotify(),
      fetchPosts(),
      _initAnalytics(),
      fetchPortfolio(),
    ]);
    // Poll weather every 10 minutes
    _weatherTimer = Timer.periodic(const Duration(minutes: 10), (_) => fetchWeather());
    // Poll Spotify every 3 seconds for a faster real-time feel
    _spotifyTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchSpotify());
  }

  Future<void> fetchPortfolio() async {
    try {
      _portfolio = await _api.fetchPortfolio();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updatePortfolioSection(String section, dynamic content) async {
    try {
      await _api.updatePortfolioSection(section, content);
      await fetchPortfolio(); // Refresh local data
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _initAnalytics() async {
    try {
      // Get or Generate Unique Visitor ID
      const visitorIdKey = 'unique_visitor_id';
      String? visitorId = html.window.localStorage[visitorIdKey];
      
      if (visitorId == null || visitorId.isEmpty) {
        visitorId = const Uuid().v4();
        html.window.localStorage[visitorIdKey] = visitorId;
      }

      // Send ID to backend for conditional increment
      await _api.incrementViews(visitorId);
      
      _totalViews = await _api.fetchTotalViews();
      notifyListeners();
      _connectToViewersWs();
    } catch (_) {}
  }

  void _connectToViewersWs() {
    try {
      final url = _api.currentViewersWsUrl;
      _wsChannel = WebSocketChannel.connect(Uri.parse(url));
      _wsChannel!.stream.listen(
        (data) {
          final map = jsonDecode(data as String) as Map<String, dynamic>;
          _currentViewers = map['count'] as int? ?? 1;
          notifyListeners();
        },
        onError: (_) {
          // Retry later
          Future.delayed(const Duration(seconds: 10), _connectToViewersWs);
        },
        onDone: () {
          Future.delayed(const Duration(seconds: 10), _connectToViewersWs);
        },
      );
    } catch (_) {}
  }

  Future<void> fetchWeather() async {
    try {
      _weather = await _api.fetchWeather();
      _weatherLoading = false;
      notifyListeners();
    } catch (_) {
      _weatherLoading = false;
    }
  }

  Future<void> _fetchSpotify() async {
    try {
      _spotify = await _api.fetchNowPlaying();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchPosts() async {
    _postsLoading = true;
    _postsError = null;
    notifyListeners();
    try {
      _posts = await _api.fetchPosts();
      _postsLoading = false;
      notifyListeners();
    } catch (e) {
      _postsLoading = false;
      _postsError = e.toString();
      notifyListeners();
    }
  }

  Future<void> createPost({
    String? title,
    required String content,
    List<String> images = const [],
    String? videoUrl,
    String? link,
  }) async {
    final post = await _api.createPost(
      title: title,
      content: content,
      images: images,
      videoUrl: videoUrl,
      link: link,
    );
    _posts.insert(0, post);
    notifyListeners();
  }

  Future<void> deletePost(int id) async {
    await _api.deletePost(id);
    _posts.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  String get spotifyAuthUrl => _api.spotifyAuthUrl;

  @override
  void dispose() {
    _weatherTimer?.cancel();
    _spotifyTimer?.cancel();
    super.dispose();
  }
}
