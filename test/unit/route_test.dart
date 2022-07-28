import 'package:utopia_dart_framework/utopia_dart_framework.dart';
import 'package:test/test.dart';

void main() async {
  final route = Route('GET', '/');
  test('method', () {
    expect('GET', route.method);
  });

  test('path', () {
    expect('/', route.path);
  });

  test('description', () {
    expect('', route.description);
    route.desc('new route');
    expect('new route', route.description);
  });

  test('params', () {
    route.param(key: 'x', defaultValue: '').param(key: 'y', defaultValue: '');
    expect(2, route.params.length);
  });

  test('resources', () {
    expect([], route.injections);

    route.inject('user').inject('time').action(() {});

    expect(2, route.injections.length);
    expect('user', route.injections[0]);
    expect('time', route.injections[1]);
  });

  test('label', () {
    expect(route.getLabel('key', defaultValue: 'default'), 'default');
    route.label('key', 'value');
    expect(route.getLabel('key', defaultValue: 'default'), 'value');
  });
}
