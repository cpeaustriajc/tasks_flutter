enum VideoPlatform { youtube }

abstract class VideoPlatformParser {
  VideoPlatform get platform;
  bool supports(String url);
  String? extractId(String url);
}

class YouTubeParser implements VideoPlatformParser {
  static const Set<String> _allowedHosts = {
    'youtu.be',
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'music.youtube.com',
  };

  final _idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  @override
  VideoPlatform get platform => VideoPlatform.youtube;

  @override
  bool supports(String url) {
    final u = Uri.tryParse(url);

    if (u == null) return false;
    if (!(u.isScheme('http') || u.isScheme('https'))) return false;
    if (!_allowedHosts.contains(u.host.toLowerCase())) return false;

    return true;
  }

  @override
  String? extractId(String url) {
    final u = Uri.tryParse(url);

    if (u == null) return null;
    if (!(u.isScheme('http') || u.isScheme('https'))) return null;

    final host = u.host.toLowerCase();

    if (!(_allowedHosts.contains(host))) return null;

    String? candidate;

    if (host == 'youtu.be') {
      candidate = u.pathSegments.isNotEmpty ? u.pathSegments.first : null;
    } else {
      candidate = u.queryParameters['v'];
      if (candidate == null || candidate.isEmpty) {
        final first = u.pathSegments.first;
        if (first == 'embed' || first == 'shorts') {
          candidate = u.pathSegments[1];
        }
      }
    }

    if (candidate == null) return null;
    candidate = candidate.split('?').first.split('#').first;
    if (!_idPattern.hasMatch(candidate)) return null;
    return candidate;
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
