import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_wifi_share/providers/file_provider.dart';
import 'package:quick_wifi_share/providers/settings_provider.dart';

class BookmarksDialog {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            final bookmarks = settings.bookmarkedFolders;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.bookmarks_rounded, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Bookmarked Folders',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (bookmarks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.bookmark_border, size: 48, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text('No bookmarked folders yet',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              )),
                          ],
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: bookmarks.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final path = bookmarks[i];
                          final fileProvider = context.read<FileProvider>();
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.folder_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                            ),
                            title: Text(
                              path.split('/').last,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(path, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
                              onPressed: () {
                                settings.removeBookmark(path);
                              },
                            ),
                            onTap: () {
                              fileProvider.setPath(path);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}