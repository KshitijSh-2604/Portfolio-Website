// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Manages owner authentication via browser localStorage.
/// Only the portfolio owner can create/delete posts and upload images.
class AuthManager {
  static const _key = 'portfolio_auth_token';

  static String? get token => html.window.sessionStorage[_key];

  static bool get isOwner => token != null && token!.isNotEmpty;

  static void setToken(String tok) {
    html.window.sessionStorage[_key] = tok;
  }

  static void logout() {
    html.window.sessionStorage.remove(_key);
  }
}
