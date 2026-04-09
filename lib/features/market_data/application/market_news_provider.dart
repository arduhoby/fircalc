import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../settings/application/display_settings_controller.dart';
import '../domain/market_news_item.dart';

final marketNewsProvider = FutureProvider<List<MarketNewsItem>>((ref) async {
  final settings = ref.watch(displaySettingsProvider);
  final client = http.Client();
  ref.onDispose(client.close);

  final service = MarketNewsService(client: client);
  return service.fetchAll(
    settings.marketNewsSources,
    selectedSource: settings.marketNewsSelectedSource,
  );
});

class MarketNewsService {
  const MarketNewsService({required this.client});

  final http.Client client;

  Future<List<MarketNewsItem>> fetchAll(
    List<String> sources, {
    String selectedSource = '',
  }) async {
    final items = <MarketNewsItem>[];
    for (final rawUrl in sources) {
      final normalizedUrl =
          rawUrl.trim() ==
              'https://bigpara.hurriyet.com.tr/haberler/sondakika-haberleri/'
          ? 'https://bigpara.hurriyet.com.tr/rss/'
          : rawUrl.trim();
      if (selectedSource.trim().isNotEmpty &&
          !_sourceMatches(normalizedUrl, selectedSource)) {
        continue;
      }
      final uri = Uri.tryParse(normalizedUrl);
      if (uri == null) continue;
      try {
        final response = await client.get(uri);
        if (response.statusCode != 200) continue;
        items.addAll(
          _parse(uri, utf8.decode(response.bodyBytes, allowMalformed: true)),
        );
      } catch (_) {
        continue;
      }
    }

    items.sort((a, b) {
      final aTime = a.publishedAt;
      final bTime = b.publishedAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    final deduped = <String>{};
    return items
        .where((item) => deduped.add('${item.sourceLabel}|${item.title}'))
        .take(20)
        .toList();
  }

  bool _sourceMatches(String normalizedUrl, String selectedSource) {
    final selected = selectedSource.trim();
    if (selected.isEmpty) return true;
    if (normalizedUrl == selected) return true;
    final normalizedHost = Uri.tryParse(normalizedUrl)?.host ?? '';
    final selectedHost = Uri.tryParse(selected)?.host ?? '';
    return normalizedHost.isNotEmpty && normalizedHost == selectedHost;
  }

  List<MarketNewsItem> _parse(Uri uri, String body) {
    if (uri.host.contains('github.com') &&
        uri.path.contains('/bakinazik/rss')) {
      return const [];
    }
    if (_looksLikeRss(body)) {
      return _parseRss(uri, body);
    }
    if (uri.host.contains('bigpara.hurriyet.com.tr')) {
      return _parseBigpara(uri, body);
    }
    return _parseGeneric(uri, body);
  }

  bool _looksLikeRss(String body) {
    final head = body.substring(0, body.length > 400 ? 400 : body.length);
    return head.contains('<rss') || head.contains('<feed');
  }

  List<MarketNewsItem> _parseRss(Uri uri, String body) {
    final itemBlocks = RegExp(
      r'<item\b[\s\S]*?</item>',
      caseSensitive: false,
    ).allMatches(body).map((match) => match.group(0)!).toList();
    final entryBlocks = RegExp(
      r'<entry\b[\s\S]*?</entry>',
      caseSensitive: false,
    ).allMatches(body).map((match) => match.group(0)!).toList();
    final items = <MarketNewsItem>[];

    for (final block in [...itemBlocks, ...entryBlocks]) {
      final title = _decodeXml(_firstTag(block, 'title'));
      final link = _extractLink(block, uri);
      final publishedAt = _parseRssDate(
        _firstTag(block, 'pubDate') ??
            _firstTag(block, 'published') ??
            _firstTag(block, 'updated'),
      );
      if (title.isEmpty || link == null) continue;
      items.add(
        MarketNewsItem(
          title: title,
          url: link,
          sourceLabel: _sourceLabel(uri),
          publishedAt: publishedAt,
        ),
      );
    }

    return items;
  }

  List<MarketNewsItem> _parseBigpara(Uri uri, String body) {
    final compact = body.replaceAll('\r', ' ').replaceAll('\n', ' ');
    final rowPattern = RegExp(
      r'<li[^>]*>\s*<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>\s*</li>\s*<li[^>]*>\s*(\d{2}\.\d{2}\.\d{4})\s*</li>\s*<li[^>]*>\s*(\d{2}:\d{2})\s*</li>',
      caseSensitive: false,
      dotAll: true,
    );
    final items = <MarketNewsItem>[];

    for (final match in rowPattern.allMatches(compact)) {
      final href = match.group(1)?.trim();
      final titleHtml = match.group(2)?.trim() ?? '';
      final date = match.group(3)?.trim();
      final time = match.group(4)?.trim();
      if (href == null || titleHtml.isEmpty || date == null || time == null) {
        continue;
      }

      final title = _stripHtml(titleHtml);
      final publishedAt = _parseTrDateTime(date, time);
      if (title.isEmpty) continue;
      items.add(
        MarketNewsItem(
          title: title,
          url: uri.resolve(href).toString(),
          sourceLabel: 'Bigpara',
          publishedAt: publishedAt,
        ),
      );
      if (items.length >= 10) break;
    }

    if (items.isNotEmpty) return items;

    final plain = _stripHtml(
      body
          .replaceAll('</li>', '\n')
          .replaceAll('</p>', '\n')
          .replaceAll('</div>', '\n')
          .replaceAll('<br>', '\n')
          .replaceAll('<br/>', '\n')
          .replaceAll('<br />', '\n'),
    );
    final lines = plain
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final startIndex = lines.indexOf('Konu');
    if (startIndex == -1) return const [];

    final textItems = <MarketNewsItem>[];
    for (var i = startIndex + 3; i + 2 < lines.length; i += 3) {
      final title = lines[i];
      final date = lines[i + 1];
      final time = lines[i + 2];
      if (!RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(date) ||
          !RegExp(r'^\d{2}:\d{2}$').hasMatch(time)) {
        continue;
      }
      textItems.add(
        MarketNewsItem(
          title: title,
          url: uri.toString(),
          sourceLabel: 'Bigpara',
          publishedAt: _parseTrDateTime(date, time),
        ),
      );
      if (textItems.length >= 15) break;
    }

    return textItems;
  }

  List<MarketNewsItem> _parseGeneric(Uri uri, String body) {
    final titleMatch = RegExp(
      r'<title[^>]*>(.*?)</title>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(body);
    final title = _stripHtml(titleMatch?.group(1) ?? '');
    if (title.isEmpty) return const [];
    return [
      MarketNewsItem(title: title, url: uri.toString(), sourceLabel: uri.host),
    ];
  }

  String _stripHtml(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _firstTag(String block, String tag) {
    final match = RegExp(
      '<$tag[^>]*>([\\s\\S]*?)</$tag>',
      caseSensitive: false,
    ).firstMatch(block);
    return match?.group(1);
  }

  String? _extractLink(String block, Uri baseUri) {
    final atomLink = RegExp(
      r'<link[^>]*href="([^"]+)"[^>]*/?>',
      caseSensitive: false,
    ).firstMatch(block);
    if (atomLink != null) {
      return baseUri.resolve(atomLink.group(1)!.trim()).toString();
    }
    final textLink = _firstTag(block, 'link');
    if (textLink == null || textLink.trim().isEmpty) return null;
    return baseUri.resolve(_decodeXml(textLink)).toString();
  }

  DateTime? _parseRssDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final text = raw.trim();
    return DateTime.tryParse(text) ??
        (() {
          try {
            return HttpDate.parse(text);
          } catch (_) {
            return null;
          }
        })();
  }

  String _decodeXml(String? raw) {
    if (raw == null) return '';
    return raw
        .replaceAll('<![CDATA[', '')
        .replaceAll(']]>', '')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  String _sourceLabel(Uri uri) {
    if (uri.host.contains('bigpara.hurriyet.com.tr')) return 'Bigpara';
    return uri.host.replaceFirst('www.', '');
  }

  DateTime? _parseTrDateTime(String date, String time) {
    final dateParts = date.split('.');
    final timeParts = time.split(':');
    if (dateParts.length != 3 || timeParts.length != 2) return null;
    final day = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final year = int.tryParse(dateParts[2]);
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (day == null ||
        month == null ||
        year == null ||
        hour == null ||
        minute == null) {
      return null;
    }
    return DateTime(year, month, day, hour, minute);
  }
}
