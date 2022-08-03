import 'dart:convert';
import 'dart:io';

class Response {
  String body;
  int status = 200;
  ContentType contentType = ContentType.text;
  bool disablePayload = false;
  final Map<String, String> _headers;
  final List<Cookie> _cookies = [];

  Map<String, String> get headers {
    _headers[HttpHeaders.contentTypeHeader] = contentType.toString();
    _headers[HttpHeaders.setCookieHeader] =
        _cookies.map((cookie) => cookie.toString()).join(',');
    return _headers;
  }

  List<Cookie> get cookies => _cookies;

  Response(this.body, {this.status = 200, Map<String, String>? headers})
      : _headers = headers ?? {};

  Response addHeader(String key, String value) {
    _headers[key] = value;
    return this;
  }

  Response removeHeader(String key) {
    _headers.remove(key);
    return this;
  }

  Response addCookie(Cookie cookie) {
    _cookies.add(cookie);
    return this;
  }

  Response removeCookie(Cookie cookie) {
    _cookies.removeWhere((element) => element.name == cookie.name);
    return this;
  }

  void json(Map<String, dynamic> data, {int status = HttpStatus.ok}) {
    contentType = ContentType.json;
    body = jsonEncode(data);
  }

  void text(String data, {int status = HttpStatus.ok}) {
    contentType = ContentType.text;
    this.status = status;
    body = data;
  }

  void html(String data, {int status = HttpStatus.ok}) {
    contentType = ContentType.html;
    this.status = status;
    body = data;
  }

  void noContent() {
    status = HttpStatus.noContent;
    body = '';
  }
}
