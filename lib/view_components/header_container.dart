import 'package:flutter/material.dart';

class HeaderContainer extends StatelessWidget {
  const HeaderContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        boxShadow: [
          BoxShadow(
            blurRadius: 2.0,
            spreadRadius: 2.0,
            offset: const Offset(0.0, -1.5),
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.5),
          ),
        ],
      ),
      child: child,
    );
  }
}
