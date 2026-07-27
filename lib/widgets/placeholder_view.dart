import 'package:flutter/material.dart';

import 'common/empty_state.dart';

/// Shown on screens whose real content hasn't been built yet, and on
/// empty/blank states elsewhere. Kept as a thin wrapper around
/// [FullEmptyState] so every call site gets the current design without
/// changes.
class PlaceholderView extends StatelessWidget {
  const PlaceholderView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return FullEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}