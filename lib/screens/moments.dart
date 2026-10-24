import 'dart:math';
import 'package:flutter/material.dart';
import '../socket_service.dart';
import '../utils.dart';

class Moments extends StatelessWidget {
  const Moments({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('朋友圈')),
      body: StreamBuilder<void>(
        stream: app.onChange,
        initialData: null,
        builder: (context, _) {
          final moments = app.moments;
          return ListView.builder(
            itemCount: moments.length,
            itemBuilder: (_, i) {
              final m = moments[i];
              final author = m['author'] ?? '';
              final likes = List<String>.from(m['likes'] ?? []);
              final comments = List<Map<String, dynamic>>.from(m['comments'] ?? []);
              final imgs = <int>[];
              if (m['images'] is List) {
                for (final x in m['images']) {
                  if (x is num) imgs.add(x.toInt());
                }
              }
              final liked = likes.contains(app.meName);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          avatarWidget(author, size: 40),
                          const SizedBox(width: 10),
                          Text(author,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if ((m['text'] ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(m['text'], style: const TextStyle(fontSize: 15)),
                        ),
                      if (imgs.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 3,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                            children: imgs
                                .map((hue) => Container(
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          gradient: gradientFromHue(hue)),
                                    ))
                                .toList(),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(fmtTime(m['time'] ?? 0),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => app.likeMoment(m['id']),
                            child: Row(
                              children: [
                                Icon(
                                    liked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: liked ? Colors.red : null,
                                    size: 18),
                                const SizedBox(width: 4),
                                Text(liked ? '取消' : '赞'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          InkWell(
                            onTap: () => _showComment(context, m['id']),
                            child: const Row(
                              children: [
                                Icon(Icons.comment_outlined, size: 18),
                                SizedBox(width: 4),
                                Text('评论'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (likes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '❤️ ' +
                                  likes
                                      .map((l) => l == app.meName ? '我' : l)
                                      .join('，'),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ...comments.map((c) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${c['from'] == app.meName ? '我' : c['from']}：${c['text']}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          )),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _publish(context),
        icon: const Icon(Icons.add),
        label: const Text('发表'),
      ),
    );
  }

  void _showComment(BuildContext context, String postId) {
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('评论'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '说点什么…'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final t = ctl.text.trim();
              if (t.isNotEmpty) app.commentMoment(postId, t);
              Navigator.pop(context);
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }

  void _publish(BuildContext context) {
    showDialog(context: context, builder: (_) => const MomentPublishDialog());
  }
}

class MomentPublishDialog extends StatefulWidget {
  const MomentPublishDialog({super.key});

  @override
  State<MomentPublishDialog> createState() => _MomentPublishDialogState();
}

class _MomentPublishDialogState extends State<MomentPublishDialog> {
  final TextEditingController _ctl = TextEditingController();
  final List<int> _imgs = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('发表朋友圈'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ctl,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(hintText: '这一刻的想法…'),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _imgs
                  .map((h) => Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: gradientFromHue(h)),
                        child: IconButton(
                          icon:
                              const Icon(Icons.close, color: Colors.white),
                          onPressed: () => setState(() => _imgs.remove(h)),
                        ),
                      ))
                  .toList(),
            ),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _imgs.add(Random().nextInt(360))),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('添加图片'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            app.publishMoment(_ctl.text.trim(), List<int>.from(_imgs));
            Navigator.pop(context);
          },
          child: const Text('发表'),
        ),
      ],
    );
  }
}
