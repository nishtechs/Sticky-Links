import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/link_item.dart';

class LinkCard extends StatelessWidget {
  final LinkItem link;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ColorScheme colorScheme;

  const LinkCard({
    super.key,
    required this.link,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.colorScheme,
  });

  void _showContextMenu(BuildContext context, Offset position) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'open',
          child: Row(
            children: [
              Icon(Icons.open_in_new_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Open Link'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy_rounded, size: 20, color: colorScheme.secondary),
              const SizedBox(width: 12),
              const Text('Copy URL'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Edit Link'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 20, color: colorScheme.error),
              const SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: colorScheme.error)),
            ],
          ),
        ),
      ],
    );

    if (result == 'open') {
      onTap();
    } else if (result == 'copy') {
      Clipboard.setData(ClipboardData(text: link.url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('URL copied to clipboard!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (result == 'edit') {
      onEdit();
    } else if (result == 'delete') {
      if (context.mounted) {
        _showDeleteDialog(context);
      }
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Link'),
        content: Text('Are you sure you want to delete "${link.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerLow,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Favicon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: colorScheme.primaryContainer,
                    ),
                    child: link.faviconUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              link.faviconUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                            ),
                          )
                        : _buildFallbackIcon(),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          link.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          link.url,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (link.description != null && link.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            link.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.outline,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Actions
                  IconButton(
                    icon: Icon(Icons.open_in_new_rounded, color: colorScheme.primary),
                    onPressed: onTap,
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_rounded, color: colorScheme.primary),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
                    onPressed: () => _showDeleteDialog(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    String initial = link.title.isNotEmpty ? link.title[0].toUpperCase() : '?';
    // Generate a consistent random color based on the title
    final int hash = link.title.hashCode;
    final color = Color.fromRGBO(
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      (hash & 0x0000FF),
      1.0,
    );
    // Mix with white for pastel look
    final pastelColor = Color.lerp(color, Colors.white, 0.4) ?? colorScheme.primaryContainer;

    return Container(
      decoration: BoxDecoration(
        color: pastelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: pastelColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }
}
