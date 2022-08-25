import 'package:test/test.dart';
import 'package:utopia_framework/src/validators/hostname.dart';

void main() {
  final hostname1 = Hostname();
  final hostname2 = Hostname([
    'myweb.vercel.app',
    'myweb.com',
    '*.myapp.com',
    '*.*.myrepo.com',
  ]);

  group(
    'HostName |',
    () {
      test(
        'getDescription(): should return proper description message',
        () {
          const expectedValue =
              'Value must be a valid hostname without path, port or protocol.';

          expect(hostname1.getDescription(), expectedValue);
        },
      );

      test(
        'getType(): should return proper data type',
        () {
          expect(hostname1.getType(), 'string');
        },
      );

      test(
        'isArray(): should return false',
        () {
          expect(hostname1.isArray(), false);
        },
      );

      test(
        'isValid(): should check the validity and return proper boolean value',
        () {
          expect(hostname1.isValid('myweb.com'), true);
          expect(hostname1.isValid('httpmyweb.com'), true);
          expect(hostname1.isValid('httpsmyweb.com'), true);
          expect(hostname1.isValid('wsmyweb.com'), true);
          expect(hostname1.isValid('wssmyweb.com'), true);
          expect(hostname1.isValid('vercel.app'), true);
          expect(hostname1.isValid('web.vercel.app'), true);
          expect(hostname1.isValid('my-web.vercel.app'), true);
          expect(hostname1.isValid('my-project.my-web.vercel.app'), true);
          expect(hostname1.isValid('myapp.co.uk'), true);
          expect(hostname1.isValid('*.myapp.com'), true);
          expect(hostname1.isValid('myapp.*'), true);
          expect(hostname1.isValid('*'), true);
          expect(
            hostname1.isValid('my-commit.my-project.my-web.vercel.app'),
            true,
          );

          expect(hostname1.isValid('https://myweb.com'), false);
          expect(hostname1.isValid('ws://myweb.com'), false);
          expect(hostname1.isValid('wss://myweb.com'), false);
          expect(hostname1.isValid('http://myweb.com'), false);
          expect(hostname1.isValid('http://myweb.com:3000'), false);
          expect(hostname1.isValid('http://myweb.com/blog'), false);
          expect(hostname1.isValid('myweb.com/blog'), false);
          expect(hostname1.isValid('myweb.com/blog/article1'), false);
          expect(hostname1.isValid('myweb.com:80'), false);
          expect(hostname1.isValid('myweb.com:3000'), false);

          expect(hostname2.isValid('myweb.vercel.app'), true);
          expect(hostname2.isValid('myweb.com'), true);
          expect(hostname2.isValid('project1.myapp.com'), true);
          expect(hostname2.isValid('project2.myapp.com'), true);
          expect(hostname2.isValid('project-with-dash.myapp.com'), true);
          expect(hostname2.isValid('anything.myapp.com'), true);
          expect(hostname2.isValid('commit1.project1.myrepo.com'), true);
          expect(hostname2.isValid('commit2.project3.myrepo.com'), true);
          expect(
            hostname2.isValid('commit-with-dash.project-with-dash.myrepo.com'),
            true,
          );

          expect(hostname2.isValid('myweb.vercel.com'), false);
          expect(hostname2.isValid('myweb2.vercel.app'), false);
          expect(hostname2.isValid('vercel.app'), false);
          expect(hostname2.isValid('mycommit.myweb.vercel.app'), false);
          expect(hostname2.isValid('myweb.eu'), false);
          expect(hostname2.isValid('project.myweb.eu'), false);
          expect(hostname2.isValid('commit.project.myweb.eu'), false);
          expect(hostname2.isValid('anything.myapp.eu'), false);
          expect(hostname2.isValid('anything.myapp.eu'), false);
          expect(hostname2.isValid('commit.anything.myapp.com'), false);
          expect(hostname2.isValid('myrepo.com'), false);
          expect(hostname2.isValid('project1.myrepo.com'), false);
          expect(hostname2.isValid('line1.commit1.project1.myrepo.com'), false);
        },
      );
    },
  );
}
