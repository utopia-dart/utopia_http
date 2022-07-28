import 'dart:async';
import 'dart:collection';
import 'package:utopia_dart_framework/src/request.dart';
import 'package:utopia_dart_framework/src/response.dart';
import 'package:utopia_dart_framework/src/server.dart';
import 'package:utopia_dart_framework/src/validation_exception.dart';
import 'route.dart';

class App {
  static final Map<String, Map<String, Route>> _routes = {
    Request.get: {},
    Request.post: {},
    Request.put: {},
    Request.patch: {},
    Request.delete: {},
    Request.head: {},
  };
  static Map<String, Map<String, Route>> get routes => _routes;
  static final Map<String, ResourceCallback> _resourceCallbacks = {};
  static bool _sorted = false;
  static final Map<String, List> _errors = {'*': []};
  static final Map<String, List<Callback>> _init = {'*': []};
  static final Map<String, List<Callback>> _shutdown = {'*': []};
  static final Map<String, List<Callback>> _options = {'*': []};

  final Map<String, dynamic> _resources = {
    'error': null,
  };
  final List _matches = [];
  Route? route;

  static serve(Server server) {
    server.serve((request) => App().run(request));
  }

  static Route get(String url) {
    return addRoute(Request.get, url);
  }

  static Route post(String url) {
    return addRoute(Request.post, url);
  }

  static Route patch(String url) {
    return addRoute(Request.patch, url);
  }

  static Route put(String url) {
    return addRoute(Request.put, url);
  }

  static Route delete(String url) {
    return addRoute(Request.delete, url);
  }

  static void init({
    required Function callback,
    List<String> resources = const [],
    String group = '*',
  }) {
    if (_init[group] == null) {
      _init[group] = [];
    }
    _init[group]!.add(Callback(callback, resources));
  }

  static void shutdown({
    required Function callback,
    List<String> resources = const [],
    String group = '*',
  }) {
    if (_shutdown[group] == null) {
      _shutdown[group] = [];
    }
    _shutdown[group]!.add(Callback(callback, resources));
  }

  static void options({
    required Function callback,
    List<String> resources = const [],
    String group = '*',
  }) {
    if (_options[group] == null) {
      _options[group] = [];
    }
    _options[group]!.add(Callback(callback, resources));
  }

  static void error({
    required Function callback,
    List<String> resources = const [],
    String group = '*',
  }) {
    if (_errors[group] == null) {
      _errors[group] = [];
    }
    _errors[group]!.add(Callback(callback, ['error', ...resources]));
  }

  static Route addRoute(String method, String path) {
    final route = Route(method, path);
    _routes[method]![path] = route;
    _sorted = false;
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
    if (route != null) {
      return route;
    }

    final method =
        request.method == Request.head ? Request.get : request.method;

    final mroutes = _routes[method]!;
    for (final entry in mroutes.entries) {
      final regex = entry.key.replaceAll(RegExp(':[^/]+'), '([^/]+)');
      final reqUrl = '/${request.url.path}';
      if (RegExp(regex).hasMatch(reqUrl)) {
        for (var m in RegExp(regex).allMatches(reqUrl)) {
          if (m.groupCount > 0 && m[1] != null) {
            _matches.add(m[1]!);
          }
        }
        route = entry.value;
        if (route != null &&
            route!.path == '/' &&
            '/${request.url.path}' != route!.path) {
          return null;
        }
        return route;
      }
    }

    if (route != null &&
        route!.path == '/' &&
        '/${request.url.path}' != route!.path) {
      return null;
    }
    return route;
  }

  FutureOr<Response> execute(Route route, Request request) async {
    final args = {};
    final groups = route.getGroups();
    final keyRegex =
        '^${route.path.replaceAll(RegExp(':[^/]+'), ':([^/]+)')}\$';
    var keys = [];
    for (var m in RegExp(keyRegex).allMatches(route.path)) {
      if (m.groupCount > 0 && m[1] != null) {
        keys.add(m[1]!);
      }
    }
    final values = {};
    for (var element in keys) {
      values[element.toString()] = _matches.removeAt(0);
    }

    try {
      if (route.middleware) {
        // call init functions
        for (final init in _init['*']!) {
          if (init.resources.isNotEmpty) {
            init.callback.call(getResources(init.resources));
          } else {
            init.callback.call();
          }
        }
      }

      for (final group in groups) {
        for (final init in (_init[group] ?? [])) {
          if (init.resources.isNotEmpty) {
            init.callback.call(getResources(init.resources));
          } else {
            init.callback.call();
          }
        }
      }

      final params = await request.getParams();

      route.params.forEach((key, param) {
        final arg = params[key] ?? param.defaultValue;
        var value = values[key] ?? arg;
        value = value == '' || value == null ? param.defaultValue : value;
        validate(key, param, value);
        args[key] = value;
      });

      route.injections.forEach((key, injection) {
        args[key] = getResource(injection.name);
      });
      final response = await route.getAction().call(args);

      for (final group in groups) {
        for (final shutdown in (_shutdown[group] ?? [])) {
          if (shutdown.resources.isNotEmpty) {
            shutdown.callback.call(getResources(shutdown.resources));
          } else {
            shutdown.callback.call();
          }
        }
      }

      if (route.middleware) {
        for (final shutdown in (_shutdown['*'] ?? [])) {
          if (shutdown.resources.isNotEmpty) {
            shutdown.callback.call(getResources(shutdown.resources));
          } else {
            shutdown.callback.call();
          }
        }
      }

      return response;
    } on Exception catch (e) {
      for (final group in groups) {
        for (final error in (_errors[group] ?? [])) {
          setResource('error', () => e);
          if (error.resources.isNotEmpty) {
            error.callback.call(getResources(error.resources));
          } else {
            error.callback.call();
          }
        }
      }

      for (final error in (_errors['*'] ?? [])) {
        setResource('error', () => e);
        if (error.resources.isNotEmpty) {
          error.callback.call(getResources(error.resources));
        } else {
          error.callback.call();
        }
      }

      if (e is ValidationException) {
        final response = getResource('response');
        response.status = 400;
      }
    }
    return getResource('response');
  }

  FutureOr<Response> run(Request request) async {
    App.setResource('request', () => request);
    final response = Response('');
    App.setResource('response', () => response);
    if (!_sorted) {
      _routes.forEach((method, pathRoutes) {
        _routes[method] =
            SplayTreeMap<String, Route>.from(_routes[method]!, (a, b) {
          return b.length - a.length;
        });

        _routes[method] =
            SplayTreeMap<String, Route>.from(_routes[method]!, (a, b) {
          int result = b.split('/').length - a.split('/').length;
          if (result == 0) {
            return (a.split(':').length - 1) - (b.split(':').length - 1);
          }
          return result;
        });
      });
    }
    final r = _routes;
    _sorted = true;

    String method = request.method.toUpperCase();
    final route = match(request);
    final groups = route?.getGroups() ?? [];

    if (method == Request.head) {
      method = Request.get;
    }

    if (route != null) {
      return execute(route, request);
    } else if (method == Request.options) {
      try {
        for (final group in groups) {
          for (final option in (_options[group] ?? [])) {
            if (option.resources.isNotEmpty) {
              option.callback.call(getResources(option.resources));
            } else {
              option.callback.call();
            }
          }
        }
        return response;
      } on Exception catch (e) {
        for (final error in (_errors['*'] ?? [])) {
          setResource('error', () => e);
          if (error.resources.isNotEmpty) {
            error.callback.call(getResources(error.resources));
          } else {
            error.callback.call();
          }
        }
        return getResource('response');
      }
    }
    response.end('Not Found', status: 404);
    return response;
  }

  void validate(String key, Param param, dynamic value) {
    if ('' != value && value != null) {
      final validator = param.validator;
      if (validator != null) {
        if (!validator.isValid(value)) {
          throw ValidationException(
              'Invalid $key: ${validator.getDescription()}');
        }
      }
    } else if (!param.optional) {
      throw ValidationException('Param "$key" is not optional.');
    }
  }

  static void reset() {
    _resourceCallbacks.clear();
    _errors.clear();
    _errors['*'] = [];
    _init.clear();
    _init['*'] = [];
    _shutdown.clear();
    _shutdown['*'] = [];
    _options.clear();
    _options['*'] = [];
    _sorted = false;
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

class Callback {
  final Function callback;
  final List<String> resources;
  Callback(this.callback, this.resources);
}
