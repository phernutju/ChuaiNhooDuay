String formatTimeAgo(DateTime postedAt) {
  final diff = DateTime.now().difference(postedAt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

String formatDistance(double? km) {
  if (km == null) return '-- km';
  final meters = km * 1000;
  if (meters < 1000) return '${meters.round()} m away';
  return '${km.toStringAsFixed(1)} km away';
}
