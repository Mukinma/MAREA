enum NotificationCategory {
  chat('chat_enabled'),
  missions('missions_enabled'),
  collaborations('collaborations_enabled'),
  reactions('reactions_enabled'),
  comments('comments_enabled'),
  reminders('marea_enabled');

  const NotificationCategory(this.column);

  final String column;

  static NotificationCategory? fromPayload(Object? value) =>
      values.where((category) => category.name == value).firstOrNull;

  static NotificationCategory? fromEvent(String kind, {String? eventKey}) =>
      switch (kind) {
        'reaction' => reactions,
        'comment' => comments,
        'interest' => collaborations,
        _ when kind.startsWith('mission_') => missions,
        'marea_message' when eventKey == null => null,
        'marea_message'
            when eventKey!.startsWith('chat_message:') ||
                eventKey.startsWith('chat_request:') ||
                eventKey.startsWith('chat_rejected:') =>
          chat,
        'marea_message' => reminders,
        _ => null,
      };
}

class NotificationPreferences {
  const NotificationPreferences() : _values = const {};

  NotificationPreferences._(Map<NotificationCategory, bool> values)
    : _values = Map.unmodifiable(values);

  final Map<NotificationCategory, bool> _values;

  bool isEnabled(NotificationCategory category) => _values[category] ?? true;

  NotificationPreferences withCategory(
    NotificationCategory category,
    bool enabled,
  ) => NotificationPreferences._({..._values, category: enabled});

  factory NotificationPreferences.fromJson(Map<String, dynamic> data) {
    final legacyActivity = data['activity_enabled'] as bool? ?? true;
    final legacyMarea = data['marea_enabled'] as bool? ?? true;
    return NotificationPreferences._({
      for (final category in NotificationCategory.values)
        category:
            data[category.column] as bool? ??
            (category == NotificationCategory.chat ||
                    category == NotificationCategory.reminders
                ? legacyMarea
                : legacyActivity),
    });
  }
}
