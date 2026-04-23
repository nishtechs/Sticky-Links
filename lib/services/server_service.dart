import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import '../providers/links_provider.dart';
import '../models/link_item.dart';
import '../services/metadata_service.dart';
import 'package:uuid/uuid.dart';

class ServerService {
  static late Router _router;
  static late LinksProvider _linksProvider;

  static Future<void> start(LinksProvider provider) async {
    _linksProvider = provider;
    _router = Router();

    // Health check
    _router.get('/health', (Request request) {
      return Response.ok('Sticky Links Server is running!');
    });

    // Add link endpoint (POST)
    _router.post('/add', (Request request) async {
      try {
        final payload = await request.readAsString();
        final data = jsonDecode(payload);
        final String? url = data['url'];

        if (url == null || url.isEmpty) {
          return Response.badRequest(body: 'URL is required');
        }

        final meta = await MetadataService.fetchMetadata(url);
        final newLink = LinkItem(
          id: const Uuid().v4(),
          title: data['title'] ?? meta['title'] ?? url,
          url: url,
          description: meta['description'],
          faviconUrl: meta['faviconUrl'],
          previewImageUrl: meta['previewImageUrl'],
        );

        await _linksProvider.addLink(newLink);

        return Response.ok(
          jsonEncode({'status': 'success', 'message': 'Link added!'}),
          headers: {'content-type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: 'Error adding link: $e');
      }
    });

    // CORS handler middleware
    final handler = Pipeline()
        .addMiddleware(_corsMiddleware())
        .addHandler(_router.call);

    // Initial server at port 7551 (Sticky Links default port)
    try {
      await io.serve(handler, 'localhost', 7551);
      // debugPrint('Sticky Links Server listening on port 7551');
    } catch (e) {
      // debugPrint('Failed to start server: $e');
    }
  }

  static Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok(
            '',
            headers: {
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
              'Access-Control-Allow-Headers':
                  'Origin, Content-Type, X-Auth-Token',
            },
          );
        }
        final response = await innerHandler(request);
        return response.change(
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers':
                'Origin, Content-Type, X-Auth-Token',
          },
        );
      };
    };
  }
}
