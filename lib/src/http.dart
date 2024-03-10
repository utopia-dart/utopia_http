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

/// Http class used to bootstrap your Http server
/// You need to use one of the server adapters. Currently only
/// Shelf adapter is available
///
/// Example:
/// ```dart
/// void main() async {
///   final address = InternetAddress.anyIPv4;
///   final port = Http.getEnv('PORT', 8080);
///   final app = Http(ShelfServer(address, port), threads: 8);
///   // setup routes
///   app.get('/').inject('request').inject('response').action(
///     (Request request, Response response) {
///       response.text('Hello world');
///       return response;
///     },
///   );
///   // sart the server
///   await app.start();
/// }
/// ```
class Http {
  Http(
    this.server, {
    this.path,
    this.threads = 1,
  }) {
    _di = DI();
    _router = Router();
  }

  /// Server adapter, currently only shelf server is supported
  final Server server;

  /// Number of threads (isolates) to spawn
  final int threads;

  /// Path to server static files from
  final String? path;

  late DI _di;

  final Map<String, Map<String, Route>> _routes = {
    Request.get: <String, Route>{},
    Request.post: <String, Route>{},
    Request.put: <String, Route>{},
    Request.patch: <String, Route>{},
    Request.delete: <String, Route>{},
    Request.head: <String, Route>{},
  };

  /// Configured routes for different methods
  Map<String, Map<String, Route>> get routes => _routes;

  final List<Hook> _errors = [];
  final List<Hook> _init = [];
  final List<Hook> _shutdown = [];
  final List<Hook> _options = [];
  List<HttpServer> _servers = [];

  late final Router _router;

  Route? _wildcardRoute;

  /// Application mode
  AppMode? mode;

  /// Is application running in production mode
  bool get isProduction => mode == AppMode.production;

  /// Is application running in development mode
  bool get isDevelopment => mode == AppMode.development;

  /// Is application running in staging mode
  bool get isStage => mode == AppMode.stage;

  /// List of servers running
  List<HttpServer> get servers => _servers;

  /// Memory cached result for chosen route
  Route? route;

  /// Start the servers
  Future<List<HttpServer>> start() async {
    _servers = await server.serve(
      run,
      path: path,
      threads: threads,
    );
    return _servers;
  }

  /// Initialize a GET route
  Route get(String url) {
    return addRoute(Request.get, url);
  }

  /// Initialize a POST route
  Route post(String url) {
    return addRoute(Request.post, url);
  }

  /// Initialize a PATCH route
  Route patch(String url) {
    return addRoute(Request.patch, url);
  }

  /// Initialize a PUT route
  Route put(String url) {
    return addRoute(Request.put, url);
  }

  /// Initialize a DELETE route
  Route delete(String url) {
    return addRoute(Request.delete, url);
  }

  /// Initialize a wildcard route
  Route wildcard() {
    _wildcardRoute = Route('', '');
    return _wildcardRoute!;
  }

  /// Initialize a init hook
  /// Init hooks are ran before executing each request
  Hook init() {
    final hook = Hook()..groups(['*']);
    _init.add(hook);
    return hook;
  }

  /// Initialize shutdown hook
  /// Shutdown hooks are ran after executing the request, before the response is sent
  Hook shutdown() {
    final hook = Hook()..groups(['*']);
    _shutdown.add(hook);
    return hook;
  }

  /// Initialize options hook
  /// Options hooks are ran for OPTIONS requests
  Hook options() {
    final hook = Hook()..groups(['*']);
    _options.add(hook);
    return hook;
  }

  /// Initialize error hooks
  /// Error hooks are ran for each errors
  Hook error() {
    final hook = Hook()..groups(['*']);
    _errors.add(hook);
    return hook;
  }

  /// Get environment variable
  static dynamic getEnv(String key, [dynamic def]) {
    return Platform.environment[key] ?? def;
  }

  /// Initialize route
  Route addRoute(String method, String path) {
    final route = Route(method, path);
    _router.addRoute(route);
    return route;
  }

  /// Set resource
  /// Once set, you can use `inject` to inject
  /// these resources to set other resources or in the hooks
  /// and routes
  void setResource(
    String name,
    Function callback, {
    String context = 'utopia',
    List<String> injections = const [],
  }) =>
      _di.set(name, callback, injections: injections, context: context);

  /// Get a resource
  T getResource<T>(
    String name, {
    bool fresh = false,
    String context = 'utopia',
  }) =>
      _di.get<T>(name, fresh: fresh, context: context);

  /// Match route based on request
  Route? match(Request request) {
    var method = request.method;
    method = (method == Request.head) ? Request.get : method;
    route = _router.match(method, request.url.path);
    return route;
  }

  /// Get arguments for hooks
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
      args[injection] = _di.get(injection);
    }
    return args;
  }

  /// Execute list of given hooks
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

  /// Execute request
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

      return response ?? _di.get('response');
    } on Exception catch (e) {
      _di.set('error', () => e);
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
        final response = _di.get('response');
        response.status = 400;
      }
    }
    return _di.get('response');
  }

  /// Run the execution for given request
  FutureOr<Response> run(Request request, String context) async {
    _di.set('request', () => request);

    try {
      _di.get('response');
    } catch (e) {
      _di.set('response', () => Response(''));
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
        return _di.get<Response>('response');
      } on Exception catch (e) {
        for (final hook in _errors) {
          _di.set('error', () => e);
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
        return _di.get<Response>('response');
      }
    }
    final response = _di.get<Response>('response');
    response.text('Not Found');
    response.status = 404;

    _di.reset(); // for each run, resources should be re-generated from callbacks

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

  /// Reset various resources
  void reset() {
    _router.reset();
    _di.reset();
    _errors.clear();
    _init.clear();
    _shutdown.clear();
    _options.clear();
    mode = null;
  }

  /// Close all the servers
  Future<void> closeServer({bool force = false}) async {
    for (final server in _servers) {
      await server.close(force: force);
    }
  }
}
