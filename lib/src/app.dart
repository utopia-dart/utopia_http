import 'dart:async';

import 'package:utopia_dart_framework/src/request.dart';
import 'package:utopia_dart_framework/src/response.dart';
import 'route.dart';

class App {
  static Map<String, Map<String, Route>> routes = {
    Request.get: {},
    Request.post: {},
    Request.put: {},
    Request.patch: {},
    Request.delete: {},
    Request.head: {},
  };
  static bool sorted = false;

  static Route get(String url) {
    return addRoute(Request.get, url);
  }

  static Route post(String url) {
    return addRoute(Request.post, url);
  }

  static Route patch(String url) {
    return addRoute(Request.patch, url);
  }

  static Route addRoute(String method, String path) {
    final route = Route(method, path);
    routes[method]![path] = route;
    sorted = false;
    return route;
  }

  static FutureOr<Response> run(Request request) async {
    final method = request.method.toUpperCase();
    print(await request.getParams());

    final route = routes[method]!['/${request.url.path}'];
    if (route != null) {
      final data = route.getAction().call();
      return Response(data.toString());
    }
    return Response('not hello world');
  }
}
