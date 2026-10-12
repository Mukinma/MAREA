class NotificationPreferences {
  const NotificationPreferences({
    this.activity = true,
    this.mareaMessages = true,
  });
  final bool activity, mareaMessages;
  factory NotificationPreferences.fromJson(Map<String, dynamic> data) =>
      NotificationPreferences(
        activity: data['activity_enabled'] as bool? ?? true,
        mareaMessages: data['marea_enabled'] as bool? ?? true,
      );
}
