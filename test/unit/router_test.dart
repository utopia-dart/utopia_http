import 'package:test/test.dart';
import 'package:utopia_framework/utopia_framework.dart';

void main() {
  final router = Router();
  group('router', () {
    setUp(() {
      router.reset();
    });

    test('Can match URL', () {
      final routeIndex = Route(Request.get, '/');
      final routeAbout = Route(Request.get, '/about');
      final routeAboutMe = Route(Request.get, '/about/me');

      router.addRoute(routeIndex);
      router.addRoute(routeAbout);
      router.addRoute(routeAboutMe);

      expect(router.match(Request.get, '/'), equals(routeIndex));
      expect(
          router.match(Request.get, '/about'), equals(routeAbout));
      expect(router.match(Request.get, '/about/me'),
          equals(routeAboutMe));
    });

    test('Can match URL with placeholder', () {
      final routeBlog = Route(Request.get, '/blog');
      final routeBlogAuthors = Route(Request.get, '/blog/authors');
      final routeBlogAuthorsComments =
          Route(Request.get, '/blog/authors/comments');
      final routeBlogPost = Route(Request.get, '/blog/:post');
      final routeBlogPostComments =
          Route(Request.get, '/blog/:post/comments');
      final routeBlogPostCommentsSingle =
          Route(Request.get, '/blog/:post/comments/:comment');

      router.addRoute(routeBlog);
      router.addRoute(routeBlogAuthors);
      router.addRoute(routeBlogAuthorsComments);
      router.addRoute(routeBlogPost);
      router.addRoute(routeBlogPostComments);
      router.addRoute(routeBlogPostCommentsSingle);

      expect(router.match(Request.get, '/blog'), equals(routeBlog));
      expect(router.match(Request.get, '/blog/authors'),
          equals(routeBlogAuthors));
      expect(router.match(Request.get, '/blog/authors/comments'),
          equals(routeBlogAuthorsComments));
      expect(router.match(Request.get, '/blog/:post'),
          equals(routeBlogPost));
      expect(router.match(Request.get, '/blog/:post/comments'),
     
          equals(routeBlogPostComments));
      expect(
          router.match(Request.get, '/blog/:post/comments/:comment'),
          equals(routeBlogPostCommentsSingle));
    });

    test('Can match HTTP method', () {
      final routeGET = Route(Request.get, '/');
      final routePOST = Route(Request.post, '/');

      router.addRoute(routeGET);
      router.addRoute(routePOST);

      expect(router.match(Request.get, '/'), equals(routeGET));
      expect(router.match(Request.post, '/'), equals(routePOST));

      expect(router.match(Request.post, '/'), isNot(routeGET));
      expect(router.match(Request.get, '/'), isNot(routePOST));
    });

    test('Can match alias', () {
      final routeGET = Route(Request.get, '/target');
      routeGET.alias('/alias').alias('/alias2');

      router.addRoute(routeGET);

      expect(router.match(Request.get, '/target'), equals(routeGET));
      expect(router.match(Request.get, '/alias'), equals(routeGET));
      expect(router.match(Request.get, '/alias2'), equals(routeGET));
    });

    test('Cannot find unknown route by path', () {
      expect(router.match(Request.get, '/404'), isNull);
    });

    test('Cannot find unknown route by method', () {
      final route = Route(Request.get, '/404');

      router.addRoute(route);

      expect(router.match(Request.get, '/404'), equals(route));
    });
  });
}
