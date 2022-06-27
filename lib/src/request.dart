import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:string_scanner/string_scanner.dart';

class Request {
  static const String get = 'GET';
  static const String post = 'POST';
  static const String put = 'PUT';
  static const String patch = 'PATCH';
  static const String delete = 'DELETE';
  static const String head = 'HEAD';
  static const String options = 'OPTIONS';

  final Uri url;
  final String method;
  final Map<String, String> headers;
  final Map<String, List<String>> headersAll;
  final Encoding? encoding;
  final String? contentType;
  final Stream<List<int>>? body;
  Map<String, dynamic>? _payload;

  Request(
    this.method,
    this.url, {
    this.headers = const {},
    this.headersAll = const {},
    this.encoding,
    this.contentType,
    this.body,
  });

  dynamic getParam(String key, {dynamic defaultValue}) async {
    switch (method) {
      case put:
      case post:
      case patch:
      case delete:
        return getPayload(key, defaultValue: defaultValue);
      case get:
      default:
        return getQuery(key, defaultValue: defaultValue);
    }
  }

  Future<Map<String, dynamic>> getParams() async {
    switch (method) {
      case put:
      case post:
      case patch:
      case delete:
        return _generateInput();
      case get:
      default:
        return url.queryParameters;
    }
  }

  dynamic getPayload(String key, {dynamic defaultValue}) async {
    await _generateInput();
    return _payload![key] ?? defaultValue;
  }

  Future<Map<String, dynamic>> _generateInput() async {
    if (_payload != null) return _payload!;

    final ctype = (contentType ?? 'text/plain').split(';').first;
    print(ctype);
    switch (ctype) {
      case 'application/json':
        final bodyString = await (encoding ?? utf8).decodeStream(body!);
        _payload = jsonDecode(bodyString) as Map<String, dynamic>;
        break;
      case 'multipart/form-data':
        _payload = await _multipartFormData();
        break;
      case 'application/x-www-form-urlencoded':
      default:
        final bodyString = await (encoding ?? utf8).decodeStream(body!);
        _payload = Uri(query: bodyString).queryParameters;
    }
    return _payload!;
  }

  dynamic getQuery(String key, {dynamic defaultValue}) {
    return url.queryParameters[key] ?? defaultValue;
  }

  Future<Map<String, dynamic>> _multipartFormData() async {
    final data = await _parts
        .map<_FormData?>((part) {
          final rawDisposition = part.headers['content-disposition'];
          if (rawDisposition == null) return null;

          final formDataParams =
              _parseFormDataContentDisposition(rawDisposition);
          if (formDataParams == null) return null;

          final name = formDataParams['name'];
          if (name == null) return null;

          final filename = formDataParams['filename'];
          dynamic value;
          if (filename != null) {
            value = {
              "file": part,
              "filename": filename,
              "mimeType": part.headers['Content-Type']
            };
          } else {
            value = (encoding ?? utf8).decodeStream(part);
          }
          return _FormData._(name, filename, value);
        })
        .where((data) => data != null)
        .toList();
    final Map<String, dynamic> out = {};
    for (final item in data) {
      if (item!.filename != null) {
        out[item.name] = await item.value;
      } else {
        out[item.name] = await item.value;
      }
    }
    return out;
  }

  Stream<MimeMultipart> get _parts {
    final boundary = _extractBoundary();
    if (boundary == null) {
      throw Exception('Not a multipart request');
    }
    return MimeMultipartTransformer(boundary).bind(body!);
  }

  String? _extractBoundary() {
    if (!headers.containsKey('Content-Type')) return null;
    final contentType = MediaType.parse(headers['Content-Type']!);
    if (contentType.type != 'multipart') return null;

    return contentType.parameters['boundary'];
  }
}

final _token = RegExp(r'[^()<>@,;:"\\/[\]?={} \t\x00-\x1F\x7F]+');
final _whitespace = RegExp(r'(?:(?:\r\n)?[ \t]+)*');
final _quotedString = RegExp(r'"(?:[^"\x00-\x1F\x7F]|\\.)*"');
final _quotedPair = RegExp(r'\\(.)');

/// Parses a `content-disposition: form-data; arg1="val1"; ...` header.
Map<String, String>? _parseFormDataContentDisposition(String header) {
  final scanner = StringScanner(header);

  scanner
    ..scan(_whitespace)
    ..expect(_token);
  if (scanner.lastMatch![0] != 'form-data') return null;

  final params = <String, String>{};

  while (scanner.scan(';')) {
    scanner
      ..scan(_whitespace)
      ..scan(_token);
    final key = scanner.lastMatch![0]!;
    scanner.expect('=');

    String value;
    if (scanner.scan(_token)) {
      value = scanner.lastMatch![0]!;
    } else {
      scanner.expect(_quotedString, name: 'quoted string');
      final string = scanner.lastMatch![0]!;

      value = string
          .substring(1, string.length - 1)
          .replaceAllMapped(_quotedPair, (match) => match[1]!);
    }

    scanner.scan(_whitespace);
    params[key] = value;
  }

  scanner.expectDone();
  return params;
}

class _FormData {
  final String name;
  final dynamic value;
  final String? filename;

  _FormData._(this.name, this.filename, this.value);
}
