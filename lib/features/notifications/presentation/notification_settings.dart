import 'package:marea/core/localization/app_localizations.dart';
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
            title: Text(
              AppLocalizations.tr('Notificaciones en este celular'),
            ),
            subtitle: Text(
              !controller.configured
                  ? AppLocalizations.tr(
                      'Los avisos en este celular aún no están disponibles',
                    )
                  : controller.permissionStatus == PushPermission.granted
                  ? AppLocalizations.tr('Permitidas por Android')
                  : AppLocalizations.tr(
                      'Activa el permiso de notificaciones en Android',
                    ),
            ),
            trailing:
                controller.configured &&
                    controller.permissionStatus != PushPermission.granted
                ? TextButton(
                    onPressed: controller.busy
                        ? null
                        : controller.gateway.openSettings,
                    child: Text(AppLocalizations.tr('Permiso Android')),
                  )
                : null,
          ),
        SwitchListTile(
          title: Text(AppLocalizations.tr('Actividad de tu comunidad')),
          subtitle: Text(
            AppLocalizations.tr(
              'Reacciones, comentarios, colaboraciones y misiones',
            ),
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
          title: Text(AppLocalizations.tr('Mensajes de MAREA 👀')),
          subtitle: Text(
            AppLocalizations.tr(
              'Un empujoncito creativo después de unos días sin entrar',
            ),
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
              child: Text(AppLocalizations.tr('Reintentar')),
            ),
          ),
      ],
    ),
  );
}
