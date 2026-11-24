String formatDuration(Duration duration, {bool includeHundredths = false}) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));

  final base = hours > 0
      ? '${twoDigits(hours)}:$minutes:$seconds'
      : '$minutes:$seconds';

  if (includeHundredths) {
    final hundredths = twoDigits(
      (duration.inMilliseconds.remainder(1000) / 10).truncate(),
    );
    return '$base.$hundredths';
  }
  return base;
}
