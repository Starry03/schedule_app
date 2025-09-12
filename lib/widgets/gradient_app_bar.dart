import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// A small reusable gradient AppBar that respects ThemeProvider.primaryGradient.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final double elevation;
  final PreferredSizeWidget? bottom;

  const GradientAppBar({
    super.key,
    this.title,
    this.actions,
    this.elevation = 0,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final gradient = Provider.of<ThemeProvider>(context).primaryGradient;

    return Material(
      elevation: elevation,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    if (title != null)
                      DefaultTextStyle(
                        style: Theme.of(context).appBarTheme.titleTextStyle ??
                            const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                        child: title!,
                      ),
                    const Spacer(),
                    if (actions != null) ...actions!,
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              if (bottom != null) bottom!,
            ],
          ),
        ),
      ),
    );
  }
}
