import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/utils/result_parser.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.json});

  final String json;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool rawOpen = false;

  BoxDecoration get _card => BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
      );

  Widget _groupHeader(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ident = identityLine(widget.json);
    final overall = overallResults(widget.json);
    final fieldGroupsList = fieldGroups(widget.json);
    final checkGroupsList = checkGroups(widget.json);
    final imgs = images(widget.json);
    final rawText = pretty(widget.json);

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: _card.copyWith(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ident.title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(
                        text: ident.status.split(' ·').first,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ident.status.contains(' ·')
                            ? ident.status.substring(ident.status.indexOf(' ·'))
                            : '',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ident.counts,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Overall',
                  style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                for (final row in overall)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            kindLabel(row.kind),
                            style: const TextStyle(color: AppColors.text, fontSize: 13),
                          ),
                        ),
                        Text(
                          row.result,
                          style: TextStyle(
                            color: row.result == 'fail'
                                ? AppColors.statusError
                                : row.result == 'pass'
                                    ? AppColors.accent
                                    : AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Fields',
                  style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (fieldGroupsList.isEmpty)
                  const Text('No fields in this response', style: TextStyle(color: AppColors.muted, fontSize: 13))
                else
                  for (final group in fieldGroupsList) ...[
                    _groupHeader(sourceLabel(group.source), group.items.length),
                    for (final item in group.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.id,
                              style: const TextStyle(color: AppColors.muted, fontSize: 12),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                            SelectableText(
                              item.value,
                              style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                            if (item.score.isNotEmpty)
                              Text(
                                item.score,
                                style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                          ],
                        ),
                      ),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Checks',
                  style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (checkGroupsList.isEmpty)
                  const Text('No checks in this response', style: TextStyle(color: AppColors.muted, fontSize: 13))
                else
                  for (final group in checkGroupsList) ...[
                    _groupHeader(kindLabel(group.kind), group.items.length),
                    for (final item in group.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.id,
                                    style: const TextStyle(color: AppColors.text, fontSize: 13),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                                Text(
                                  item.result,
                                  style: TextStyle(
                                    color: item.result == 'fail'
                                        ? AppColors.statusError
                                        : item.result == 'pass'
                                            ? AppColors.accent
                                            : AppColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            if (item.extra.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  item.extra,
                                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Images',
                  style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (imgs.isEmpty)
                  const Text('No images in response.', style: TextStyle(color: AppColors.muted, fontSize: 13))
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 12.0;
                      final itemW = (constraints.maxWidth - gap) / 2;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final img in imgs)
                            SizedBox(
                              width: itemW,
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      height: 148,
                                      width: itemW,
                                      color: AppColors.bg,
                                      alignment: Alignment.center,
                                      child: Image.memory(img.bytes, fit: BoxFit.contain, height: 148),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    img.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            onTap: () => setState(() => rawOpen = !rawOpen),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: _card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Raw JSON',
                    style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  if (rawOpen) ...[
                    const SizedBox(height: 12),
                    SelectableText(
                      rawText,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
