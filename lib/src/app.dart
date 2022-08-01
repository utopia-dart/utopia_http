import 'dart:async';
import 'dart:io';
import 'app_mode.dart';
import 'hook.dart';
import 'request.dart';
import 'response.dart';
import 'route.dart';
import 'server.dart';
import 'validation_exception.dart';

class App {
  final Map<String, Map<String, Route>> _routes = {
    Request.get: <String, Route>{},
    Request.post: <String, Route>{},
    Request.put: <String, Route>{},
    Request.patch: <String, Route>{},
    Request.delete: <String, Route>{},
    Request.head: <String, Route>{},
  };
  Map<String, Map<String, Route>> get routes => _routes;
  static final Map<String, _ResourceCallback> _resourceCallbacks = {};
  bool _sorted = false;
  final List<Hook> _errors = [];
  final List<Hook> _init = [];
  final List<Hook> _shutdown = [];
  final List<Hook> _options = [];
  HttpServer? _server;

  AppMode? mode;

  bool get isProduction => mode == AppMode.production;
  bool get isDevelopment => mode == AppMode.development;
  bool get isStage => mode == AppMode.stage;
  HttpServer? get server => _server;

  final Map<String, dynamic> _resources = {
    'error': null,
  };

  final Map<String, Route> _matchedRoute = {};
  final Map<String, dynamic> _matches = {};
  Route? route;

  Future<HttpServer> serve(Server server, {String? path}) async {
    _server = await server.serve((request) => run(request), path: path);
    return _server!;
  }

  Route get(String url) {
    return addRoute(Request.get, url);
  }

  Route post(String url) {
    return addRoute(Request.post, url);
  }

  Route patch(String url) {
    return addRoute(Request.patch, url);
  }

  Route put(String url) {
    return addRoute(Request.put, url);
  }

  Route delete(String url) {
    return addRoute(Request.delete, url);
  }

  Hook init() {
    final hook = Hook()..groups(['*']);
    _init.add(hook);
    return hook;
  }

  Hook shutdown() {
    final hook = Hook()..groups(['*']);
    _shutdown.add(hook);
    return hook;
  }

  Hook options() {
    final hook = Hook()..groups(['*']);
    _options.add(hook);
    return hook;
  }

  Hook error() {
    final hook = Hook()..groups(['*']);
    _errors.add(hook);
    return hook;
  }

  static dynamic getEnv(String key, [dynamic def]) {
    return Platform.environment[key] ?? def;
  }

  Route addRoute(String method, String path) {
    final route = Route(method, path);
    _routes[method]![path] = route;
    _sorted = false;
    return route;
  }

  Route? getRoute() {
    try {
      final request = getResource('request');
      return _matchedRoute[request.url.path];
    } catch (e) {
      return null;
    }
  }

  App setRoute(Route route) {
    try {
      final request = getResource('request');
      _matchedRoute[request.url.path];
    } catch (e) {
      throw Exception('Unable to set route at this context');
    }
    return this;
  }

  static void setResource(
    String name,
    Function callback, {
    List<String> injections = const [],
  }) {
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
        (_resourceCallbacks[name]?.reset ?? true)) {
      if (_resourceCallbacks[name] == null) {
        throw Exception('Failed to find resource: "$name"');
      }

      final params = getResources(_resourceCallbacks[name]!.injections);
      _resources[name] = Function.apply(
        _resourceCallbacks[name]!.callback,
        [...params.values],
      );
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
      _validate(key, param, value);
      args[key] = value;
    });

    for (var injection in hook.injections) {
      args[injection] = getResource(injection);
    }
    return args;
  }

  Future<void> _executeHooks(
    List<Hook> hooks,
    List<String> groups,
    Future<Map<String, dynamic>> Function(Hook) argsCallback, {
    bool globalHook = false,
    bool reversedExecution = false,
  }) async {
    Future<void> executeGlobalHook() async {
      if (globalHook) {
        for (final hook in hooks) {
          if (hook.getGroups().contains('*')) {
            final arguments = await argsCallback.call(hook);
            Function.apply(
              hook.getAction(),
              [...hook.argsOrder.map((key) => arguments[key])],
            );
          }
        }
      }
    }

    Future<void> executeGroupHooks() async {
      for (final group in groups) {
        for (final hook in _init) {
          if (hook.getGroups().contains(group)) {
            final arguments = await argsCallback.call(hook);
            Function.apply(
              hook.getAction(),
              [...hook.argsOrder.map((key) => arguments[key])],
            );
          }
        }
      }
    }

    if (!reversedExecution) {
      await executeGlobalHook();
    }
    await executeGroupHooks();
    if (reversedExecution) {
      await executeGlobalHook();
    }
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
      await _executeHooks(
        _init,
        groups,
        (hook) async => _getArguments(
          hook,
          requestParams: await request.getParams(),
          values: values,
        ),
        globalHook: route.hook,
      );

      final args = _getArguments(
        route,
        requestParams: await request.getParams(),
        values: values,
      );
      final response = await Function.apply(
        route.getAction(),
        [...route.argsOrder.map((key) => args[key])],
      );

      await _executeHooks(
        _shutdown,
        groups,
        (hook) async => _getArguments(
          hook,
          requestParams: await request.getParams(),
          values: values,
        ),
        globalHook: route.hook,
        reversedExecution: true,
      );

      return response;
    } on Exception catch (e) {
      setResource('error', () => e);
      await _executeHooks(
        _errors,
        groups,
        (hook) async => _getArguments(
          hook,
          requestParams: await request.getParams(),
          values: values,
        ),
        globalHook: route.hook,
        reversedExecution: true,
      );

      if (e is ValidationException) {
        final response = getResource('response');
        response.status = 400;
      }
    }
    return getResource('response');
  }

  FutureOr<Response> run(Request request) async {
    setResource('request', () => request);

    if (_resourceCallbacks['response'] == null) {
      setResource('response', () => Response(''));
    }

    if (!_sorted) {
      _routes.forEach((method, pathRoutes) {
        _routes[method] =
            Map<String, Route>.fromEntries(_routes[method]!.entries.toList()
              ..sort((a, b) {
                return b.key.length - a.key.length;
              }));

        _routes[method] =
            Map<String, Route>.fromEntries(_routes[method]!.entries.toList()
              ..sort((a, b) {
                int result = b.key.split('/').length - a.key.split('/').length;
                if (result == 0) {
                  return (a.key.split(':').length - 1) -
                      (b.key.split(':').length - 1);
                }
                return result;
              }));
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
        _executeHooks(
          _options,
          groups,
          (hook) async => _getArguments(
            hook,
            requestParams: await request.getParams(),
          ),
          globalHook: true,
          reversedExecution: true,
        );
        return getResource('response');
      } on Exception catch (e) {
        for (final hook in _errors) {
          setResource('error', () => e);
          if (hook.getGroups().contains('*')) {
            hook.getAction().call(
                  _getArguments(hook, requestParams: await request.getParams()),
                );
          }
        }
        return getResource('response');
      }
    }
    final response = getResource('response');
    response.text('Not Found');
    response.status = 404;
    return response;
  }

  void _validate(String key, Param param, dynamic value) {
    if ('' != value && value != null) {
      final validator = param.validator;
      if (validator != null) {
        if (!validator.isValid(value)) {
          throw ValidationException(
            'Invalid $key: ${validator.getDescription()}',
          );
        }
      }
    } else if (!param.optional) {
      throw ValidationException('Param "$key" is not optional.');
    }
  }

  void reset() {
    _errors.clear();
    _init.clear();
    _shutdown.clear();
    _options.clear();
    _sorted = false;
    _matchedRoute.clear();
    _matches.clear();
    mode = null;
  }

  Future<dynamic> closeServer({bool force = false}) async {
    return _server?.close(force: force);
  }

  static void resetResources() {
    _resourceCallbacks.clear();
  }
}

class _ResourceCallback {
  final String name;
  final List<String> injections;
  final Function callback;
  final bool reset;

  _ResourceCallback(
    this.name,
    this.injections,
    this.callback, {
    this.reset = false,
  });

  _ResourceCallback copyWith({bool? reset}) {
    return _ResourceCallback(name, injections, callback, reset: reset ?? false);
  }
}
