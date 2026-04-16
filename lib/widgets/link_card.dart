import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/link_item.dart';
import '../screens/reader_page.dart';
import '../widgets/glass_container.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';

class LinkCard extends StatelessWidget {
  final LinkItem link;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onArchive;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final ColorScheme colorScheme;

  const LinkCard({
    super.key,
    required this.link,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onArchive,
    required this.colorScheme,
    this.isSelected = false,
    this.onLongPress,
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
          value: 'reader',
          child: Row(
            children: [
              Icon(Icons.article_rounded, size: 20, color: colorScheme.secondary),
              const SizedBox(width: 12),
              const Text('Open in Reader'),
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
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share_rounded, size: 20, color: colorScheme.tertiary),
              const SizedBox(width: 12),
              const Text('Share Link'),
            ],
          ),
        ),
        const PopupMenuDivider(),
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
        PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(link.isArchived ? Icons.unarchive_rounded : Icons.archive_rounded, size: 20, color: colorScheme.secondary),
              const SizedBox(width: 12),
              Text(link.isArchived ? 'Unarchive' : 'Archive'),
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
    } else if (result == 'reader') {
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReaderPage(url: link.url, title: link.title)),
      );
    } else if (result == 'copy') {
      Clipboard.setData(ClipboardData(text: link.url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('URL copied to clipboard!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
            width: 250,
          ),
        );
      }
    } else if (result == 'edit') {
      onEdit();
    } else if (result == 'share') {
      Share.share(link.url, subject: link.title);
    } else if (result == 'archive') {
      onArchive();
    } else if (result == 'delete') {
      if (context.mounted) _showDeleteDialog(context);
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
    final settings = context.watch<SettingsProvider>();
    
    return GlassContainer(
      isEnabled: settings.isGlassEnabled,
      borderRadius: 16,
      opacity: 0.1,
      child: Card(
        elevation: isSelected ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : (settings.isGlassEnabled ? Colors.white12 : Colors.transparent),
            width: 2,
          ),
        ),
        color: isSelected 
            ? colorScheme.primaryContainer.withValues(alpha: 0.3) 
            : (settings.isGlassEnabled ? Colors.transparent : colorScheme.surfaceContainerLow),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (onLongPress != null) ...[
                     Checkbox(
                       value: isSelected,
                       onChanged: (_) => onLongPress!(),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                     ),
                     const SizedBox(width: 8),
                  ],
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
                            child: CachedNetworkImage(
                              imageUrl: link.faviconUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: colorScheme.surfaceContainerHighest),
                              errorWidget: (_, __, ___) => _buildFallbackIcon(),
                            ),
                          )
                        : _buildFallbackIcon(),
                  ),
                  const SizedBox(width: 16),
                  // Preview Image (if available) - hide on very small screens to save space
                  if (link.previewImageUrl != null && MediaQuery.of(context).size.width > 400) ...[
                     Container(
                       width: 80,
                       height: 50,
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(8),
                         color: colorScheme.surfaceContainerHighest,
                       ),
                       child: ClipRRect(
                         borderRadius: BorderRadius.circular(8),
                         child: CachedNetworkImage(
                           imageUrl: link.previewImageUrl!,
                           fit: BoxFit.cover,
                           placeholder: (context, url) => const Icon(Icons.image, size: 20, color: Colors.grey),
                           errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                         ),
                       ),
                     ),
                     const SizedBox(width: 12),
                  ],
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
                  if (MediaQuery.of(context).size.width > 600) ...[
                    IconButton(
                      icon: Icon(link.isArchived ? Icons.unarchive_rounded : Icons.archive_rounded, color: colorScheme.secondary),
                      onPressed: onArchive,
                      tooltip: link.isArchived ? 'Unarchive' : 'Archive',
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_rounded, color: colorScheme.primary),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
                      onPressed: () => _showDeleteDialog(context),
                    ),
                  ] else ...[
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurfaceVariant),
                      onSelected: (value) {
                        if (value == 'open') onTap();
                        if (value == 'reader') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ReaderPage(url: link.url, title: link.title)),
                          );
                        }
                        if (value == 'copy') {
                          Clipboard.setData(ClipboardData(text: link.url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('URL copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              duration: const Duration(seconds: 2),
                              width: 250,
                            ),
                          );
                        }
                        if (value == 'archive') onArchive();
                        if (value == 'edit') onEdit();
                        if (value == 'share') Share.share(link.url, subject: link.title);
                        if (value == 'delete') _showDeleteDialog(context);
                      },
                      itemBuilder: (context) => [
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
                          value: 'reader',
                          child: Row(
                            children: [
                              Icon(Icons.article_rounded, size: 20, color: colorScheme.secondary),
                              const SizedBox(width: 12),
                              const Text('Open in Reader'),
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
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share_rounded, size: 20, color: colorScheme.tertiary),
                              const SizedBox(width: 12),
                              const Text('Share Link'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(link.isArchived ? Icons.unarchive_rounded : Icons.archive_rounded, size: 20, color: colorScheme.secondary),
                              const SizedBox(width: 12),
                              Text(link.isArchived ? 'Unarchive' : 'Archive'),
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
                              const Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                ),
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
