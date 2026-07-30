class AppDateTime {
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static DateTime? parseToLocal(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static String formatDateTime(String? value, {String fallback = ''}) {
    final parsed = parseToLocal(value);
    if (parsed == null) {
      if (value == null || value.trim().isEmpty) return fallback;
      return value.replaceFirst('T', ' ');
    }

    final month = _months[parsed.month - 1];
    final hour = parsed.hour == 0
        ? 12
        : parsed.hour > 12
        ? parsed.hour - 12
        : parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
    return '$month ${parsed.day}, ${parsed.year} • $hour:$minute $suffix';
  }

  static String formatShortDateTime(String? value, {String fallback = ''}) {
    final parsed = parseToLocal(value);
    if (parsed == null) {
      if (value == null || value.trim().isEmpty) return fallback;
      return value.replaceFirst('T', ' ');
    }

    final month = _months[parsed.month - 1];
    final hour = parsed.hour == 0
        ? 12
        : parsed.hour > 12
        ? parsed.hour - 12
        : parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour >= 12 ? 'pm' : 'am';
    return '$month ${parsed.day}, $hour:$minute $suffix';
  }

  static String formatAdminDateTime(
    String? value, {
    String fallback = 'Unknown date',
  }) {
    final parsed = parseToLocal(value);
    if (parsed == null) {
      if (value == null || value.trim().isEmpty) return fallback;
      return value.replaceFirst('T', ' ');
    }

    return '${_two(parsed.day)}-${_two(parsed.month)}-${parsed.year} '
        '${_two(parsed.hour)}:${_two(parsed.minute)}';
  }

  static String formatTimeAgo(String? value, {String fallback = 'Just now'}) {
    final parsed = parseToLocal(value);
    if (parsed == null) {
      if (value == null || value.trim().isEmpty) return fallback;
      return value.replaceFirst('T', ' ');
    }

    final difference = DateTime.now().difference(parsed);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min${difference.inMinutes == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
    return formatAdminDateTime(value, fallback: fallback);
  }

  static String? timeLeft(String? value) {
    final parsed = parseToLocal(value);
    if (parsed == null) return null;

    final difference = parsed.difference(DateTime.now());
    if (difference.isNegative) return 'Closed';
    if (difference.inHours >= 1) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} left';
    }

    final minutes = difference.inMinutes.clamp(0, 59);
    return '${minutes} min${minutes == 1 ? '' : 's'} left';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
