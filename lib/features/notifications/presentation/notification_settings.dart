import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
import '../data/push_controller.dart';
import '../data/push_gateway.dart';
import '../models/notification_preferences.dart';

class NotificationSettings extends StatelessWidget {
  const NotificationSettings({required this.controller, super.key});

  final PushController controller;

  static const _choices = {
    NotificationCategory.chat: (
      'Mensajes y solicitudes de chat',
      'Mensajes nuevos y cambios en tus solicitudes',
    ),
    NotificationCategory.missions: (
      'Misiones',
      'Postulaciones y cambios en las convocatorias',
    ),
    NotificationCategory.collaborations: (
      'Colaboraciones',
      'Interés en colaborar en tus publicaciones',
    ),
    NotificationCategory.reactions: (
      'Reacciones',
      'Reacciones a tus publicaciones y misiones',
    ),
    NotificationCategory.comments: (
      'Comentarios',
      'Comentarios en tus publicaciones y misiones',
    ),
    NotificationCategory.reminders: (
      'Recordatorios de MAREA',
      'Ideas y recordatorios ocasionales de la comunidad',
    ),
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xl,
      children: [
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ProfileMenuSection(
            title: 'En este dispositivo',
            children: [
              ProfileMenuRow(
                icon: Icons.notifications_outlined,
                title: 'Permiso de notificaciones',
                subtitle: !controller.configured
                    ? 'Los avisos en este dispositivo aún no están disponibles'
                    : controller.permissionStatus == PushPermission.granted
                    ? 'Permitidas por Android'
                    : 'Activa el permiso de notificaciones en Android',
                onTap: null,
              ),
              if (controller.configured &&
                  controller.permissionStatus != PushPermission.granted)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: controller.busy
                          ? null
                          : controller.gateway.openSettings,
                      child: const Text('Abrir ajustes de Android'),
                    ),
                  ),
                ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            const Text(
              'Elige qué avisos llegan a tu teléfono. Puedes consultar toda '
              'tu actividad en la bandeja de MAREA.',
            ),
            if (kIsWeb || defaultTargetPlatform != TargetPlatform.android)
              const Text(
                'Tu configuración se aplica a los dispositivos Android '
                'donde tienes activados los avisos de MAREA.',
              ),
            ProfileMenuSection(
              title: 'Avisos del teléfono',
              children: [
                for (final MapEntry(key: category, value: (title, description))
                    in _choices.entries)
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(title),
                    subtitle: Text(description),
                    value: controller.preferences.isEnabled(category),
                    onChanged: controller.busy || !controller.preferencesLoaded
                        ? null
                        : (value) => controller.setCategory(category, value),
                  ),
              ],
            ),
          ],
        ),
        if (controller.busy) const LinearProgressIndicator(minHeight: 3),
        if (controller.error case final error?)
          ProfileMenuSection(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    TextButton(
                      onPressed: controller.busy ? null : controller.refresh,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    ),
  );
}
