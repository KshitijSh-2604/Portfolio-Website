import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../models/weather_model.dart';
import '../models/spotify_model.dart';
import '../models/portfolio_model.dart';
import '../utils/auth_manager.dart';

import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ApiService {
  static const String _productionBaseUrl = 'https://portfolio-website-azure-ten-62.vercel.app/api';
  static const String _productionOrigin = 'https://portfolio-website-azure-ten-62.vercel.app';

  static String get _baseUrl {
    if (kIsWeb) {
      if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
        return 'http://localhost:8000/api';
      }
      return _productionBaseUrl;
    }
    return 'http://localhost:8000/api';
  }

  static String get _origin {
    if (kIsWeb) {
      if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
        return 'http://localhost:8000';
      }
      return _productionOrigin;
    }
    return 'http://localhost:8000';
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (AuthManager.token != null) 'Authorization': 'Bearer ${AuthManager.token}',
  };

  Future<String> login(String password) async {
    final response = await http.post(
      _uri('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}),
    );
    if (response.statusCode != 200) throw Exception('Incorrect password');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['token'] as String;
  }

  Future<List<PostModel>> fetchPosts() async {
    final response = await http.get(_uri('/posts'));
    if (response.statusCode != 200) throw Exception('Failed to load posts');
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => PostModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PostModel> createPost({
    String? title,
    required String content,
    List<String> images = const [],
    String? videoUrl,
    String? link,
  }) async {
    final body = <String, dynamic>{
      'content': content,
      if (title != null && title.isNotEmpty) 'title': title,
      if (images.isNotEmpty) 'images': images,
      if (videoUrl != null && videoUrl.isNotEmpty) 'videoUrl': videoUrl,
      if (link != null && link.isNotEmpty) 'link': link,
    };
    final response = await http.post(
      _uri('/posts'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    if (response.statusCode == 401) throw Exception('Not authorized');
    if (response.statusCode != 201) throw Exception('Failed to create post');
    return PostModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deletePost(int id) async {
    final response = await http.delete(
      _uri('/posts/$id'),
      headers: _authHeaders,
    );
    if (response.statusCode == 401) throw Exception('Not authorized');
    if (response.statusCode != 204) throw Exception('Failed to delete post');
  }

  Future<WeatherModel> fetchWeather() async {
    final response = await http.get(_uri('/weather'));
    if (response.statusCode != 200) throw Exception('Failed to load weather');
    return WeatherModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<SpotifyTrackModel> fetchNowPlaying() async {
    final response = await http.get(_uri('/spotify/now-playing'));
    if (response.statusCode != 200) return SpotifyTrackModel(isPlaying: false);
    return SpotifyTrackModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  String get spotifyAuthUrl => '$_baseUrl/spotify/auth';

  Future<int> fetchTotalViews() async {
    final response = await http.get(_uri('/analytics/views'));
    if (response.statusCode != 200) return 0;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['views'] as int? ?? 0;
  }

  Future<void> incrementViews(String visitorId) async {
    await http.post(
      _uri('/analytics/views/increment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'visitor_id': visitorId}),
    );
  }

  Future<void> sendContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    final body = jsonEncode({
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
    });
    final response = await http.post(
      _uri('/contact'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<PortfolioDataModel> fetchPortfolio() async {
    final response = await http.get(_uri('/portfolio'));
    if (response.statusCode != 200) throw Exception('Failed to load portfolio');
    return PortfolioDataModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> updatePortfolioSection(String section, dynamic content) async {
    final response = await http.patch(
      _uri('/portfolio/$section'),
      headers: _authHeaders,
      body: jsonEncode({'content': content}),
    );
    if (response.statusCode == 401) throw Exception('Not authorized');
    if (response.statusCode != 200) throw Exception('Failed to update section');
  }

  Future<void> updateOwnerLocation() async {
    final response = await http.post(
      _uri('/portfolio/update-location'),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) throw Exception('Failed to update location');
  }

  Future<String> uploadImage(Uint8List bytes, String filename) async {
    final uri = Uri.parse('$_baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);
    if (AuthManager.token != null) {
      request.headers['Authorization'] = 'Bearer ${AuthManager.token}';
    }

    final mimeType = lookupMimeType(filename) ?? 'image/jpeg';
    final mediaType = MediaType.parse(mimeType);

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: mediaType,
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 401) throw Exception('Not authorized');
    if (response.statusCode != 200) throw Exception('Upload failed: ${response.statusCode}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['url'] as String;
  }
}
