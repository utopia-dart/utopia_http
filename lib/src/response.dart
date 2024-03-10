import 'dart:convert';
import 'dart:io';

class Response {
  /// Response body
  String body;

  /// HTTP status
  int status = 200;

  /// Content type
  ContentType contentType = ContentType.text;

  /// Disable payload
  bool disablePayload = false;
  final Map<String, String> _headers;
  final List<Cookie> _cookies = [];

  /// Get headers
  Map<String, String> get headers {
    _headers[HttpHeaders.contentTypeHeader] = contentType.toString();
    _headers[HttpHeaders.setCookieHeader] =
        _cookies.map((cookie) => cookie.toString()).join(',');
    return _headers;
  }

  /// Get cookies
  List<Cookie> get cookies => _cookies;

  Response(this.body, {this.status = 200, Map<String, String>? headers})
      : _headers = headers ?? {};

  /// Add header
  Response addHeader(String key, String value) {
    _headers[key] = value;
    return this;
  }

  /// Remove header
  Response removeHeader(String key) {
    _headers.remove(key);
    return this;
  }

  /// Add cookie
  Response addCookie(Cookie cookie) {
    _cookies.add(cookie);
    return this;
  }

  /// Remove cookie
  Response removeCookie(Cookie cookie) {
    _cookies.removeWhere((element) => element.name == cookie.name);
    return this;
  }

  /// Set json response
  void json(Map<String, dynamic> data, {int status = HttpStatus.ok}) {
    contentType = ContentType.json;
    body = jsonEncode(data);
  }

  /// Set text response
  void text(String data, {int status = HttpStatus.ok}) {
    contentType = ContentType.text;
    this.status = status;
    body = data;
  }

  /// Set HTML response
  void html(String data, {int status = HttpStatus.ok}) {
    contentType = ContentType.html;
    this.status = status;
    body = data;
  }

  /// Set empty response
  void noContent() {
    status = HttpStatus.noContent;
    body = '';
  }
}
