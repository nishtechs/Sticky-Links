import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class ReaderPage extends StatefulWidget {
  final String url;
  final String title;

  const ReaderPage({super.key, required this.url, required this.title});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late Future<String> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = _fetchContent();
  }

  Future<String> _fetchContent() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        
        // Simple extraction: try to find 'article', or 'main', or just body
        final article = document.getElementsByTagName('article').firstOrNull ??
                       document.getElementsByTagName('main').firstOrNull ??
                       document.body;
        
        return article?.innerHtml ?? 'No content found';
      }
      return 'Failed to load content: ${response.statusCode}';
    } catch (e) {
      return 'Error loading content: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            onPressed: () {
              // Should use url_launcher but we'll assume it's handled outside or just provide feedback
            },
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.url,
                  style: TextStyle(color: colorScheme.outline, fontSize: 12),
                ),
                const Divider(height: 48),
                HtmlWidget(
                  snapshot.data ?? '',
                  textStyle: TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    color: colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                  onTapUrl: (url) {
                    // Logic to handle links inside articles
                    return true;
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }
}
