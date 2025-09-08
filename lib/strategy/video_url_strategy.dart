enum VideoPlatform { youtube }

abstract class VideoPlatformParser {
  VideoPlatform get platform;
  bool supports(String url);
  String? extractId(String url);
}

class YouTubeParser implements VideoPlatformParser {
  @override
  VideoPlatform get platform => VideoPlatform.youtube;

  @override
  bool supports(String url) {
    final u = Uri.tryParse(url);
    if (u == null || !(u.isScheme('http') || u.isScheme('https'))) return false;
    final host = u.host.toLowerCase();
    return host.contains('youtube.com') || host.contains('youtu.be');
  }

  @override
  String? extractId(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return null;
    final host = u.host.toLowerCase();
    if (host.contains('youtu.be')) {
      final id = u.pathSegments.isNotEmpty ? u.pathSegments.first : null;
      return (id != null && id.isNotEmpty) ? id : null;
    }

    if (host.contains('youtube.com')) {
      final id = u.queryParameters['v'];
      if (id != null && id.isNotEmpty) return id;
      if (u.pathSegments.length >= 2) {
        final first = u.pathSegments.first;
        if (first == 'shorts' || first == 'embed') return u.pathSegments[1];
      }
    }

    return null;
  }
}

class VideoUrlStrategy {
  VideoUrlStrategy._internal(this._parsers);

  static final VideoUrlStrategy instance = VideoUrlStrategy._internal([
    YouTubeParser(),
  ]);
  final List<VideoPlatformParser> _parsers;

  bool isPlatform(String url, VideoPlatform platform) =>
      _parsers.any((p) => p.platform == platform && p.supports(url));

  bool isYouTube(String url) => isPlatform(url, VideoPlatform.youtube);

  String? extractId(String url) {
    for (final p in _parsers) {
      if (p.supports(url)) return p.extractId(url);
    }

    return null;
  }

  String? extractIdFor(String url, VideoPlatform platform) {
    final parser = _parsers.firstWhere(
      (p) => p.platform == platform && p.supports(url),
      orElse: () => _NullParser(),
    );

    return parser is _NullParser ? null : parser.extractId(url);
  }

  void register(VideoPlatformParser parser) {
    if (_parsers.any((p) => p.platform == parser.platform)) return;
    _parsers.add(parser);
  }
}

class _NullParser implements VideoPlatformParser {
  @override
  VideoPlatform get platform => throw UnimplementedError();

  @override
  bool supports(String url) => false;

  @override
  String? extractId(String url) => null;
}
