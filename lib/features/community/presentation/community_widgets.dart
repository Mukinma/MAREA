import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/shared/widgets/marea_refresh_indicator.dart';
import 'package:marea/shared/widgets/marea_logo.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({
    required this.title,
    required this.children,
    this.subtitle,
    this.onRefresh,
    this.action,
    super.key,
  });
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final body = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 24,
        compact ? 12 : 24,
        compact ? 16 : 24,
        32,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        const MareaLogo(compact: true),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Explorar la comunidad',
                          onPressed: () => context.go('/explore'),
                          icon: const Icon(Icons.explore_outlined),
                        ),
                      ],
                    ),
                  ),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: compact ? 28 : null,
                            height: 1.08,
                          ),
                    ),
                    ?action,
                  ],
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                SizedBox(height: compact ? 20 : 28),
                ...children,
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
    return SafeArea(
      child: onRefresh == null
          ? body
          : MareaRefreshIndicator(onRefresh: onRefresh!, child: body),
    );
  }
}

class CommunityNotice extends StatelessWidget {
  const CommunityNotice({
    required this.message,
    this.icon = Icons.lightbulb_outline_rounded,
    this.onRetry,
    super.key,
  });
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.aquaDark),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

Future<bool> runCommunityAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(communityError(error))));
    }
    return false;
  }
}

String communityError(Object error) =>
    error is AppFailure ? error.message : AppFailureMapper.from(error).message;

Future<String?> askCommunityText(
  BuildContext context, {
  required String title,
  required String label,
  int maxLength = 1000,
}) async {
  // The controller is disposed with the dialog, after its closing animation.
  return showDialog<String>(
    context: context,
    builder: (_) =>
        _TextDialog(title: title, label: label, maxLength: maxLength),
  );
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.label,
    required this.maxLength,
  });
  final String title, label;
  final int maxLength;
  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final _text = TextEditingController();
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 440,
      child: TextField(
        controller: _text,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        maxLength: widget.maxLength,
        decoration: InputDecoration(labelText: widget.label),
        onChanged: (_) => setState(() {}),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _text.text.trim().length < 5
            ? null
            : () => Navigator.pop(context, _text.text.trim()),
        child: const Text('Enviar'),
      ),
    ],
  );
}

Future<bool> confirmCommunityDelete(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar publicación?'),
        content: const Text(
          'Se retirará de tu perfil y de los guardados de otras personas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ??
    false;

/// Caches requests across rebuilds and permits retry/refresh without fake data.
class CommunityLoad<T> extends StatefulWidget {
  const CommunityLoad({required this.load, required this.builder, super.key});
  final Future<T> Function() load;
  final Widget Function(T value, Future<void> Function() reload) builder;
  @override
  State<CommunityLoad<T>> createState() => _CommunityLoadState<T>();
}

class _CommunityLoadState<T> extends State<CommunityLoad<T>> {
  late Future<T> _future = widget.load();
  Future<void> _reload() async {
    if (!mounted) return;
    final next = widget.load();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      /* FutureBuilder shows the error. */
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return CommunityNotice(
          message: communityError(snapshot.error!),
          icon: Icons.cloud_off_outlined,
          onRetry: _reload,
        );
      }
      return widget.builder(snapshot.data as T, _reload);
    },
  );
}
