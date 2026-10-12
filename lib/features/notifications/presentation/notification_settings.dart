import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../data/push_controller.dart';
import '../data/push_gateway.dart';
import '../models/notification_preferences.dart';

class NotificationSettings extends StatelessWidget {
  const NotificationSettings({required this.controller, super.key});
  final PushController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Column(
      children: [
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notificaciones en este celular'),
            subtitle: Text(
              !controller.configured
                  ? 'Los avisos en este celular aún no están disponibles'
                  : controller.permissionStatus == PushPermission.granted
                  ? 'Permitidas por Android'
                  : 'Activa el permiso de notificaciones en Android',
            ),
            trailing:
                controller.configured &&
                    controller.permissionStatus != PushPermission.granted
                ? TextButton(
                    onPressed: controller.busy
                        ? null
                        : controller.gateway.openSettings,
                    child: const Text('Permiso Android'),
                  )
                : null,
          ),
        SwitchListTile(
          title: const Text('Actividad de tu comunidad'),
          subtitle: const Text(
            'Reacciones, comentarios, colaboraciones y misiones',
          ),
          value: controller.preferences.activity,
          onChanged: controller.busy
              ? null
              : (value) => controller.save(
                  NotificationPreferences(
                    activity: value,
                    mareaMessages: controller.preferences.mareaMessages,
                  ),
                ),
        ),
        SwitchListTile(
          title: const Text('Mensajes de MAREA 👀'),
          subtitle: const Text(
            'Un empujoncito creativo después de unos días sin entrar',
          ),
          value: controller.preferences.mareaMessages,
          onChanged: controller.busy
              ? null
              : (value) => controller.save(
                  NotificationPreferences(
                    activity: controller.preferences.activity,
                    mareaMessages: value,
                  ),
                ),
        ),
        if (controller.error != null)
          ListTile(
            title: Text(controller.error!),
            trailing: TextButton(
              onPressed: controller.busy ? null : controller.refresh,
              child: const Text('Reintentar'),
            ),
          ),
      ],
    ),
  );
}
