import 'dart:async';
import 'dart:collection';

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

  static final Map<String, dynamic> _resources = {
    'error': null,
  };

  Route? _route = null;
  List _matches = [];

  static Map<String, ResourceCallback> _resourceCallbacks = {};

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

  static void setResource(String name, Function callback,
      {List<String> injections = const []}) {
    if (name == 'utopia') {
      throw Exception('utopia is a reserved resource.');
    }
    _resourceCallbacks[name] =
        ResourceCallback(name, injections, callback, reset: true);
  }

  dynamic getResource(String name, {bool fresh = false}) {
    if (name == 'utopia') return this;
    if (_resources[name] == null ||
        fresh ||
        (_resourceCallbacks[name]?.reset ?? false)) {
      if (_resourceCallbacks[name] == null) {
        throw Exception('Failed to find resource: "$name"');
      }

      final params = getResources(_resourceCallbacks[name]!.injections);
      if (params.isNotEmpty) {
        _resources[name] =
            _resourceCallbacks[name]!.callback.call(params.values);
      } else {
        _resources[name] = _resourceCallbacks[name]!.callback.call();
      }

      return _resources[name];
    }
  }

  Map<String, dynamic> getResources(List<String> names) {
    final resources = <String, dynamic>{};
    for (final name in names) {
      resources[name] = getResource(name);
    }
    return resources;
  }

  Route? match(Request request) {
    if (_route != null) {
      return _route;
    }

    final method =
        request.method == Request.head ? Request.get : request.method;

    final mroutes = routes[method]!;
    for (final entry in mroutes.entries) {
      final regex = entry.key.replaceAll(RegExp(':[^/]+'), '([^/]+)');
      final reqUrl = '/${request.url.path}';
      if (RegExp(regex).hasMatch(reqUrl)) {
        for (var m in RegExp(regex).allMatches(reqUrl)) {
          if (m[1] != null) {
            _matches.add(m[1]!);
          }
        }
        _route = entry.value;
        if (_route != null &&
            _route!.path == '/' &&
            '/${request.url.path}' != _route!.path) {
          return null;
        }
        return _route;
      }
    }

    if (_route != null &&
        _route!.path == '/' &&
        '/${request.url.path}' != _route!.path) {
      return null;
    }
    return _route;
  }

  FutureOr<Response> execute(Route route, Request request) async {
    final args = {};
    final groups = route.getGroups();
    final keyRegex =
        '^' + route.path.replaceAll(RegExp(':[^/]+'), ':([^/]+)') + '\$';
    var keys = [];
    for (var m in RegExp(keyRegex).allMatches(route.path)) {
      if (m[1] != null) {
        keys.add(m[1]!);
      }
    }
    final values = {};
    keys.forEach((element) {
      values[element.toString()] = _matches.removeAt(0);
    });

    if (route.middleware) {
      // call init functions
    }

    groups.forEach((element) {
      // call group init
    });

    final params = await request.getParams();
    route.params.forEach((key, param) {
      final arg = params[key] ?? param.defaultValue;
      var value = values[key] ?? arg;
      value = value == '' || value == null ? param.defaultValue : value;

      // validate
      // validate(key, param, value);
      args[key] = value;
    });

    route.injections.forEach((key, injection) {
      args[key] = getResource(injection.name);
    });
    final response = await route.getAction().call(args);

    groups.forEach((element) {
      // run shutdown for each group
    });

    if (route.middleware) {
      // call shutdown for group '*'
    }

    return response;
  }

  FutureOr<Response> run(Request request, Response response) async {
    App.setResource('request', () => request);
    App.setResource('response', () => response);

    if (!sorted) {
      routes.forEach((method, pathRoutes) {
        routes[method] =
            SplayTreeMap<String, Route>.from(routes[method]!, (a, b) {
          return b.length - a.length;
        });

        routes[method] =
            SplayTreeMap<String, Route>.from(routes[method]!, (a, b) {
          int result = b.split('/').length - a.split('/').length;
          if (result == 0) {
            return (a.split(':').length - 1) - (b.split(':').length - 1);
          }
          return result;
        });
      });
    }
    final r = routes;
    sorted = true;

    String method = request.method.toUpperCase();
    final route = match(request);
    final groups = route?.getGroups() ?? [];

    if (method == Request.head) {
      method = Request.get;
    }

    if (route != null) {
      return execute(route, request);
    }

    response.end('Not Found', status: 404);
    return response;
  }
}

class ResourceCallback {
  final String name;
  final List<String> injections;
  final Function callback;
  final bool reset;

  ResourceCallback(this.name, this.injections, this.callback,
      {this.reset = false});
}
