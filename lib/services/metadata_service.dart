import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class MetadataService {
  /// Fetches rich metadata (title, description, favicon, preview image) for a given URL
  static Future<Map<String, String?>> fetchMetadata(String url) async {
    try {
      if (!url.startsWith('http')) {
        url = 'https://$url';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return {};

      final document = html_parser.parse(response.body);
      final Map<String, String?> metadata = {};

      // 1. Title
      metadata['title'] = _getMeta(document, 'og:title') ?? 
                        _getMeta(document, 'twitter:title') ?? 
                        document.querySelector('title')?.text;

      // 2. Description
      metadata['description'] = _getMeta(document, 'og:description') ?? 
                               _getMeta(document, 'description') ?? 
                               _getMeta(document, 'twitter:description');

      // 3. Preview Image
      metadata['previewImageUrl'] = _getMeta(document, 'og:image') ?? 
                                  _getMeta(document, 'twitter:image:src') ?? 
                                  _getMeta(document, 'twitter:image');

      // 4. Favicon
      metadata['faviconUrl'] = _getFavicon(document, url);

      return metadata;
    } catch (e) {
      return {};
    }
  }

  static String? _getMeta(Document document, String property) {
    return document
        .querySelector('meta[property="$property"]')
        ?.attributes['content'] ??
        document
        .querySelector('meta[name="$property"]')
        ?.attributes['content'];
  }

  static String? _getFavicon(Document document, String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final String rootUrl = '${uri.scheme}://${uri.host}';

    // Check link tags
    final faviconNode = document.querySelector('link[rel="icon"]') ?? 
                        document.querySelector('link[rel="shortcut icon"]') ??
                        document.querySelector('link[rel="apple-touch-icon"]');

    String? path = faviconNode?.attributes['href'];
    if (path == null) return '$rootUrl/favicon.ico';

    if (path.startsWith('http')) return path;
    if (path.startsWith('//')) return 'https:$path';
    if (path.startsWith('/')) return '$rootUrl$path';
    return '$rootUrl/$path';
  }
}
