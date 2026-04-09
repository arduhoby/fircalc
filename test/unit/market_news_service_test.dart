import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mfcalc/features/market_data/application/market_news_provider.dart';

void main() {
  test('parses Bigpara list rows into news items', () async {
    final service = MarketNewsService(client: _FakeClient());
    final items = await service.fetchAll([
      'https://bigpara.hurriyet.com.tr/haberler/sondakika-haberleri/',
    ]);

    expect(items, isNotEmpty);
    expect(items.first.sourceLabel, 'Bigpara');
    expect(items.first.title, contains('BRENT PETROL'));
    expect(items.first.publishedAt, isNotNull);
  });

  test('parses Bigpara rss feed into news items', () async {
    final service = MarketNewsService(client: _RssFakeClient());
    final items = await service.fetchAll([
      'https://bigpara.hurriyet.com.tr/rss/',
    ]);

    expect(items, isNotEmpty);
    expect(items.first.sourceLabel, 'Bigpara');
    expect(items.first.title, contains('Piyasa'));
    expect(items.first.url, 'https://bigpara.hurriyet.com.tr/haber/ornek-rss/');
    expect(items.first.publishedAt, isNotNull);
  });
}

class _FakeClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    const html = '''
    <html><body>
    <li><a href="/haber/ornek-1/">BRENT PETROL YUKSELDI</a></li>
    <li>11.10.2021</li>
    <li>14:16</li>
    <li><a href="/haber/ornek-2/">DEMIR CEVHERI YUKSELDI</a></li>
    <li>11.10.2021</li>
    <li>14:14</li>
    </body></html>
    ''';
    final response = http.Response(html, 200, request: request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      request: request,
      headers: response.headers,
    );
  }
}

class _RssFakeClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    const rss = '''
    <?xml version="1.0" encoding="utf-8"?>
    <rss version="2.0">
      <channel>
        <title>Bigpara RSS</title>
        <item>
          <title><![CDATA[Piyasa yorumu]]></title>
          <link>https://bigpara.hurriyet.com.tr/haber/ornek-rss/</link>
          <pubDate>Thu, 09 Apr 2026 10:30:00 GMT</pubDate>
        </item>
      </channel>
    </rss>
    ''';
    final response = http.Response(rss, 200, request: request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      request: request,
      headers: response.headers,
    );
  }
}
