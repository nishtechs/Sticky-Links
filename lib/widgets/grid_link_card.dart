import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/link_item.dart';
import '../screens/reader_page.dart';
import '../widgets/glass_container.dart';
import '../providers/settings_provider.dart';

class GridLinkCard extends StatelessWidget {
  final LinkItem link;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onArchive;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final ColorScheme colorScheme;

  const GridLinkCard({
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReaderPage(url: link.url, title: link.title)),
      );
    } else if (result == 'copy') {
      Clipboard.setData(ClipboardData(text: link.url));
    } else if (result == 'edit') {
      onEdit();
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
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
            ? colorScheme.primaryContainer.withOpacity(0.3) 
            : (settings.isGlassEnabled ? Colors.transparent : colorScheme.surfaceContainerLow),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
            child: Stack(
              children: [
                InkWell(
                  onTap: onTap,
                  onLongPress: onLongPress,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Header Image or Favicon
                        Stack(
                          children: [
                            if (link.previewImageUrl != null)
                               Container(
                                 height: 100,
                                 width: double.infinity,
                                 decoration: BoxDecoration(
                                   borderRadius: BorderRadius.circular(12),
                                   color: colorScheme.surfaceVariant,
                                 ),
                                 child: ClipRRect(
                                   borderRadius: BorderRadius.circular(12),
                                   child: CachedNetworkImage(
                                     imageUrl: link.previewImageUrl!,
                                     fit: BoxFit.cover,
                                     placeholder: (context, url) => Container(color: colorScheme.surfaceVariant),
                                     errorWidget: (_, __, ___) => const Center(child: Icon(Icons.image, size: 40)),
                                   ),
                                 ),
                               ),
                            if (link.previewImageUrl == null)
                              Center(
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: colorScheme.primaryContainer,
                                  ),
                                  child: link.faviconUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: CachedNetworkImage(
                                            imageUrl: link.faviconUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(color: colorScheme.surfaceVariant),
                                            errorWidget: (_, __, ___) => _buildFallbackIcon(),
                                          ),
                                        )
                                      : _buildFallbackIcon(),
                                ),
                              ),
                            if (link.previewImageUrl != null && link.faviconUrl != null)
                               Positioned(
                                 bottom: 4,
                                 left: 4,
                                 child: Container(
                                   padding: const EdgeInsets.all(2),
                                   decoration: BoxDecoration(
                                     color: Colors.white,
                                     borderRadius: BorderRadius.circular(6),
                                     boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                   ),
                                   child: ClipRRect(
                                     borderRadius: BorderRadius.circular(4),
                                     child: CachedNetworkImage(
                                       imageUrl: link.faviconUrl!,
                                       width: 16,
                                       height: 16,
                                       fit: BoxFit.cover,
                                     ),
                                   ),
                                 ),
                               ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                flex: 2,
                                child: Text(
                                  link.title,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Flexible(
                                flex: 1,
                                child: Text(
                                  Uri.parse(link.url).host,
                                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(link.isArchived ? Icons.unarchive_rounded : Icons.archive_rounded, size: 18, color: colorScheme.secondary),
                              onPressed: onArchive,
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_rounded, size: 18, color: colorScheme.primary),
                              onPressed: onEdit,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (onLongPress != null)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onLongPress!(),
                      shape: const CircleBorder(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    String initial = link.title.isNotEmpty ? link.title[0].toUpperCase() : '?';
    final int hash = link.title.hashCode;
    final color = Color.fromRGBO((hash & 0xFF0000) >> 16, (hash & 0x00FF00) >> 8, (hash & 0x0000FF), 1.0);
    final pastelColor = Color.lerp(color, Colors.white, 0.4) ?? colorScheme.primaryContainer;

    return Container(
      decoration: BoxDecoration(color: pastelColor, borderRadius: BorderRadius.circular(14)),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: pastelColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }
}
