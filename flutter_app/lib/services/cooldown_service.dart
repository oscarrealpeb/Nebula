class CooldownService {
  final Map<String, DateTime> _expirations = {};

  int remainingSeconds(String key) {
    final expiration = _expirations[key];
    if (expiration == null) return 0;

    final seconds = expiration.difference(DateTime.now()).inSeconds;
    if (seconds <= 0) {
      _expirations.remove(key);
      return 0;
    }
    return seconds;
  }

  bool canTrigger(String key) {
    return remainingSeconds(key) == 0;
  }

  void start(String key, Duration duration) {
    _expirations[key] = DateTime.now().add(duration);
  }
}
