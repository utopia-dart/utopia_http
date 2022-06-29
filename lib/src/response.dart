import 'dart:io';

class Response {
  String body;
  int _status = 200;
  ContentType contentType = ContentType.text;
  bool disablePayload = false;
  final Map<String, String> _headers;
  final List<Cookie> _cookies = [];

  Response(this.body, {int status = 200, Map<String, String>? headers})
      : _headers = headers ?? {},
        _status = status;

  int get status => _status;

  end(message, {int status = 200}) {
    body = message;
    status = 200;
  }

  Response addHeader(String key, String value) {
    _headers[key] = value;
    return this;
  }

  Response removeHeader(String key) {
    _headers.remove(key);
    return this;
  }

  Response.s404(String message, {Map<String, String>? headers})
      : this(message, headers: headers ?? {});

  Response.send(String message, {int status = 200})
      : this(message, status: status);
}
