import 'dart:async';
import 'dart:io';

import 'package:utopia_di/utopia_di.dart';

import 'app_mode.dart';
import 'request.dart';
import 'response.dart';
import 'route.dart';
import 'router.dart';
import 'server.dart';
import 'validation_exception.dart';

class Http {
  Http(
    this.server, {
    this.path,
    this.threads = 1,
  }) {
    di = DI();
    _router = Router();
  }

  final Server server;
  final int threads;
  final String? path;

  late DI di;
  final Map<String, Map<String, Route>> _routes = {
    Request.get: <String, Route>{},
    Request.post: <String, Route>{},
    Request.put: <String, Route>{},
    Request.patch: <String, Route>{},
    Request.delete: <String, Route>{},
    Request.head: <String, Route>{},
  };
  Map<String, Map<String, Route>> get routes => _routes;
  final List<Hook> _errors = [];
  final List<Hook> _init = [];
  final List<Hook> _shutdown = [];
  final List<Hook> _options = [];
  List<HttpServer> _servers = [];

  late final Router _router;

  Route? _wildcardRoute;

  AppMode? mode;

  bool get isProduction => mode == AppMode.production;
  bool get isDevelopment => mode == AppMode.development;
  bool get isStage => mode == AppMode.stage;
  List<HttpServer> get servers => _servers;

  /// Memory cached result for chosen route
  Route? route;

  Future<List<HttpServer>> start() async {
    _servers = await server.serve(
      run,
      path: path,
      threads: threads,
    );
    return _servers;
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

  Route wildcard() {
    _wildcardRoute = Route('', '');
    return _wildcardRoute!;
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
    _router.addRoute(route);
    return route;
  }

  void setResource(
    String name,
    Function callback, {
    String context = 'utopia',
    List<String> injections = const [],
  }) =>
      di.set(name, callback, injections: injections, context: context);

  dynamic getResource<T>(
    String name, {
    bool fresh = false,
    String context = 'utopia',
  }) =>
      di.get<T>(name, fresh: fresh, context: context);

  Route? match(Request request) {
    var method = request.method;
    method = (method == Request.head) ? Request.get : method;
    route = _router.match(method, request.url.path);
    return route;
  }

  Map<String, dynamic> _getArguments(
    Hook hook, {
    required String context,
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
      args[injection] = di.get(injection);
    }
    return args;
  }

  Future<void> _executeHooks(
    List<Hook> hooks,
    List<String> groups,
    Future<Map<String, dynamic>> Function(Hook) argsCallback, {
    bool globalHook = false,
    bool globalHooksFirst = true,
  }) async {
    Future<void> executeGlobalHook() async {
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

    if (globalHooksFirst && globalHook) {
      await executeGlobalHook();
    }
    await executeGroupHooks();
    if (!globalHooksFirst && globalHook) {
      await executeGlobalHook();
    }
  }

  FutureOr<Response> execute(
    Route route,
    Request request,
    String context,
  ) async {
    final groups = route.getGroups();
    final pathValues = route.getPathValues(request);

    try {
      await _executeHooks(
        _init,
        groups,
        (hook) async => _getArguments(
          hook,
          context: context,
          requestParams: await request.getParams(),
          values: pathValues,
        ),
        globalHook: route.hook,
      );

      final args = _getArguments(
        route,
        context: context,
        requestParams: await request.getParams(),
        values: pathValues,
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
          context: context,
          requestParams: await request.getParams(),
          values: pathValues,
        ),
        globalHook: route.hook,
        globalHooksFirst: false,
      );

      return response ?? di.get('response');
    } on Exception catch (e) {
      di.set('error', () => e);
      await _executeHooks(
        _errors,
        groups,
        (hook) async => _getArguments(
          hook,
          context: context,
          requestParams: await request.getParams(),
          values: pathValues,
        ),
        globalHook: route.hook,
        globalHooksFirst: false,
      );

      if (e is ValidationException) {
        final response = di.get('response');
        response.status = 400;
      }
    }
    return di.get('response');
  }

  FutureOr<Response> run(Request request, String context) async {
    di.set('request', () => request);

    try {
      di.get('response');
    } catch (e) {
      di.set('response', () => Response(''));
    }

    var method = request.method.toUpperCase();
    var route = match(request);
    final groups = (route is Route) ? route.getGroups() : <String>[];

    if (method == Request.head) {
      method = Request.get;
    }

    if (route == null && _wildcardRoute != null) {
      route = _wildcardRoute;
      route!.path = request.url.path;
    }

    if (route != null) {
      return execute(route, request, context);
    } else if (method == Request.options) {
      try {
        _executeHooks(
          _options,
          groups,
          (hook) async => _getArguments(
            hook,
            context: context,
            requestParams: await request.getParams(),
          ),
          globalHook: true,
          globalHooksFirst: false,
        );
        return di.get('response');
      } on Exception catch (e) {
        for (final hook in _errors) {
          di.set('error', () => e);
          if (hook.getGroups().contains('*')) {
            hook.getAction().call(
                  _getArguments(
                    hook,
                    context: context,
                    requestParams: await request.getParams(),
                  ),
                );
          }
        }
        return di.get('response');
      }
    }
    final response = di.get('response');
    response.text('Not Found');
    response.status = 404;

    di.reset(); // for each run, resources should be re-generated from callbacks

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
    _router.reset();
    di.reset();
    _errors.clear();
    _init.clear();
    _shutdown.clear();
    _options.clear();
    mode = null;
  }

  Future<void> closeServer({bool force = false}) async {
    for (final server in _servers) {
      await server.close(force: force);
    }
  }
}
