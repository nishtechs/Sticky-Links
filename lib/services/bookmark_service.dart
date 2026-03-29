import 'package:html/parser.dart' as html_parser;
import 'package:uuid/uuid.dart';
import '../models/link_item.dart';

class BookmarkService {
  /// Parses standard Bookmark HTML file (exported from Chrome/Firefox/Edge)
  static List<LinkItem> parseBookmarkHtml(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final List<LinkItem> parsedLinks = [];
    
    // Most browsers use <DT><A ...> in a nested <DL> structure
    final anchorTags = document.getElementsByTagName('a');

    for (var a in anchorTags) {
       final String? url = a.attributes['href'];
       final String title = a.text.trim();
       
       if (url != null && url.startsWith('http')) {
          // Attempt to find parent context for category (usually DL > DT > H3 or similar)
          String? category;
          var parent = a.parent;
          // Look up for a header tag <h3> or equivalent which represents the folder
          while(parent != null && parent.localName != 'body') {
            final h3 = parent.children.where((c) => c.localName == 'h3').firstOrNull;
            if (h3 != null) {
               category = h3.text.trim();
               break;
            }
            parent = parent.parent;
          }

          parsedLinks.add(
            LinkItem(
              id: const Uuid().v4(), 
              title: title.isEmpty ? url : title, 
              url: url,
              category: category,
              timestamp: _parseAddDate(a.attributes['add_date']),
            )
          );
       }
    }
    return parsedLinks;
  }

  static int _parseAddDate(String? addDate) {
    if (addDate == null) return DateTime.now().millisecondsSinceEpoch;
    try {
      // Chrome uses Unix time in seconds
      return int.parse(addDate) * 1000;
    } catch(e) {
      return DateTime.now().millisecondsSinceEpoch;
    }
  }
}
