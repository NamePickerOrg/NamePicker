import 'package:flutter/material.dart';

/// Material 3 风格的设置项卡片组件

class SettingsCard extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final String? description; // 新增描述字段
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const SettingsCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.description,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        hoverColor: colorScheme.primary.withOpacity(0.06),
        splashColor: colorScheme.primary.withOpacity(0.10),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            border: Border.all(color: colorScheme.outlineVariant, width: 1),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: leading!,
                ),
                const SizedBox(width: 18),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600),
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 10),
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: colorScheme.onSurfaceVariant),
                        child: subtitle!,
                      ),
                    ],
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Divider(height: 20, thickness: 1, color: colorScheme.outlineVariant),
                      Text(
                        description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 18),
                Container(
                  // decoration: BoxDecoration(
                  //   color: colorScheme.secondaryContainer.withOpacity(0.7),
                  //   borderRadius: BorderRadius.circular(10),
                  // ),
                  padding: const EdgeInsets.all(8),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
