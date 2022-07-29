import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:utopia_dart_framework/src/request.dart';
import 'package:utopia_dart_framework/src/response.dart';
import 'package:utopia_dart_framework/src/server.dart';
import 'package:utopia_dart_framework/src/validation_exception.dart';
import 'hook.dart';
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
  static final Map<String, _ResourceCallback> _resourceCallbacks = {};
  static bool _sorted = false;
  static final List<Hook> _errors = [];
  static final List<Hook> _init = [];
  static final List<Hook> _shutdown = [];
  static final List<Hook> _options = [];

  final Map<String, dynamic> _resources = {
    'error': null,
  };

  final Map<String, Route> _matchedRoute = {};
  final Map<String, dynamic> _matches = {};
  Route? route;

  Future<HttpServer> serve(Server server) {
    return server.serve((request) => run(request));
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

  static Hook init() {
    final hook = Hook()..groups(['*']);
    _init.add(hook);
    return hook;
  }

  static Hook shutdown() {
    final hook = Hook()..groups(['*']);
    _shutdown.add(hook);
    return hook;
  }

  static Hook options() {
    final hook = Hook()..groups(['*']);
    _options.add(hook);
    return hook;
  }

  static Hook error() {
    final hook = Hook()..groups(['*']);
    _errors.add(hook);
    return hook;
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
        _ResourceCallback(name, injections, callback, reset: true);
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
        _resources[name] = _resourceCallbacks[name]!.callback.call(params);
      } else {
        _resources[name] = _resourceCallbacks[name]!.callback.call();
      }
    }
    _resourceCallbacks[name] = _resourceCallbacks[name]!.copyWith(reset: false);
    return _resources[name];
  }

  Map<String, dynamic> getResources(List<String> names) {
    final resources = <String, dynamic>{};
    for (final name in names) {
      resources[name] = getResource(name);
    }
    return resources;
  }

  Route? match(Request request) {
    if (_matchedRoute[request.url.path] != null) {
      return _matchedRoute[request.url.path];
    }

    final method =
        request.method == Request.head ? Request.get : request.method;

    final mroutes = _routes[method]!;
    _matches[request.url.path] ??= [];
    for (final entry in mroutes.entries) {
      final regex = entry.key.replaceAll(RegExp(':[^/]+'), '([^/]+)');
      final reqUrl = '/${request.url.path}';
      if (RegExp(regex).hasMatch(reqUrl)) {
        for (var m in RegExp(regex).allMatches(reqUrl)) {
          if (m.groupCount > 0 && m[1] != null) {
            _matches[request.url.path].add(m[1]!);
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
    if (route != null) {
      _matchedRoute[request.url.path] = route!;
    }
    return route;
  }

  Map<String, dynamic> _getArguments(
    Hook hook, {
    required Map<String, dynamic> requestParams,
    Map<String, dynamic> values = const {},
  }) {
    final args = <String, dynamic>{};
    hook.params.forEach((key, param) {
      final arg = requestParams[key] ?? param.defaultValue;
      var value = values[key] ?? arg;
      value = value == '' || value == null ? param.defaultValue : value;
      validate(key, param, value);
      args[key] = value;
    });

    for (var injection in hook.injections) {
      args[injection] = getResource(injection);
    }
    return args;
  }

  FutureOr<Response> execute(Route route, Request request) async {
    final groups = route.getGroups();
    final keyRegex =
        '^${route.path.replaceAll(RegExp(':[^/]+'), ':([^/]+)')}\$';
    var keys = [];
    for (var m in RegExp(keyRegex).allMatches(route.path)) {
      if (m.groupCount > 0 && m[1] != null) {
        keys.add(m[1]!);
      }
    }
    final values = <String, dynamic>{};
    for (var element in keys) {
      values[element.toString()] = _matches[request.url.path].removeAt(0);
    }

    try {
      if (route.hook) {
        for (final hook in _init) {
          if (hook.getGroups().contains('*')) {
            hook.getAction().call(_getArguments(hook,
                requestParams: await request.getParams(), values: values));
          }
        }
      }

      for (final group in groups) {
        for (final hook in _init) {
          if (hook.getGroups().contains(group)) {
            hook.getAction().call(_getArguments(hook,
                requestParams: await request.getParams(), values: values));
          }
        }
      }

      final args = _getArguments(route,
          requestParams: await request.getParams(), values: values);
      final response = await route.getAction().call(args);

      for (final group in groups) {
        for (final hook in _shutdown) {
          if (hook.getGroups().contains(group)) {
            hook.getAction().call(_getArguments(hook,
                requestParams: await request.getParams(), values: values));
          }
        }
      }

      if (route.hook) {
        for (final hook in _shutdown) {
          if (hook.getGroups().contains('*')) {
            hook.getAction().call(_getArguments(hook,
                requestParams: await request.getParams(), values: values));
          }
        }
      }

      return response;
    } on Exception catch (e) {
      for (final group in groups) {
        for (final hook in _errors) {
          setResource('error', () => e);
          if (hook.getGroups().contains(group)) {
            hook.getAction().call(_getArguments(hook,
                requestParams: await request.getParams(), values: values));
          }
        }
      }

      for (final hook in _errors) {
        setResource('error', () => e);
        if (hook.getGroups().contains('*')) {
          hook.getAction().call(_getArguments(hook,
              requestParams: await request.getParams(), values: values));
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
          for (final hook in _options) {
            if (hook.getGroups().contains(group)) {
              hook.getAction().call(_getArguments(hook,
                  requestParams: await request.getParams()));
            }
          }
        }
        for (final hook in _options) {
          if (hook.getGroups().contains('*')) {
            hook.getAction().call(_getArguments(
                  hook,
                  requestParams: await request.getParams(),
                ));
          }
        }
        return response;
      } on Exception catch (e) {
        for (final hook in _errors) {
          setResource('error', () => e);
          if (hook.getGroups().contains('*')) {
            hook.getAction().call(
                _getArguments(hook, requestParams: await request.getParams()));
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
    _init.clear();
    _shutdown.clear();
    _options.clear();
    _sorted = false;
  }
}

class _ResourceCallback {
  final String name;
  final List<String> injections;
  final Function callback;
  final bool reset;

  _ResourceCallback(this.name, this.injections, this.callback,
      {this.reset = false});

  _ResourceCallback copyWith({bool? reset}) {
    return _ResourceCallback(name, injections, callback, reset: reset ?? false);
  }
}
