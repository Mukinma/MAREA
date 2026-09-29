import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/shared/widgets/marea_logo.dart';
import 'package:marea/shared/widgets/creative_artwork.dart';
import 'package:marea/shared/widgets/marea_surface.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({required this.child, super.key, this.register = false});
  final Widget child;
  final bool register;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.paper,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, bounds) {
          final wide = bounds.maxWidth >= 1024;
          final padding = wide
              ? 48.0
              : bounds.maxWidth < 400
              ? 16.0
              : 24.0;
          final form = MareaSurface(
            floating: true,
            color: AppColors.paper,
            radius: 32,
            padding: EdgeInsets.all(wide ? 32 : 20),
            child: child,
          );
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(padding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (bounds.maxHeight - 2 * padding).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(
                              flex: 4,
                              child: Padding(
                                padding: EdgeInsets.only(right: 64),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MareaLogo(),
                                    SizedBox(height: 56),
                                    CreativeArtwork(),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(flex: 5, child: form),
                          ],
                        )
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: MareaLogo(compact: true),
                              ),
                              const SizedBox(height: 28),
                              form,
                            ],
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
