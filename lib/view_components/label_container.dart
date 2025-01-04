import 'package:flutter/material.dart';
import 'package:ohnote/tools/clip_shadow_path.dart';

class LabelContainer extends StatelessWidget {
  const LabelContainer({
    super.key,
    required this.content,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    this.onTap,
    this.onLongPress,
    this.color,
    this.minWidth = 75.0,
  });

  final void Function()? onTap;
  final void Function()? onLongPress;
  final EdgeInsets padding;
  final Color? color;
  final double minWidth;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return ClipShadowPath(
      shadow: Shadow(
        color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.7),
        offset: const Offset(1.5, 2.5),
        blurRadius: 1.5,
      ),
      clipper: const _LabelClipper(),
      child: Material(
        shadowColor: Colors.black,
        color: color ?? Theme.of(context).colorScheme.primary,
        child: InkWell(
          splashColor: Color.lerp(Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.onPrimary, 0.5)?.withValues(alpha: 0.35),
          onTap: onTap,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(padding.left, padding.top, padding.right + 8.0, padding.bottom),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class _LabelClipper extends CustomClipper<Path> {
  const _LabelClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 4)
      ..arcToPoint(const Offset(4, 0), radius: const Radius.circular(4))
      ..lineTo(size.width - 22, 0)
      ..arcToPoint(Offset(size.width - 12, 2), radius: const Radius.elliptical(10, 2))
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width - 12, size.height - 2)
      ..arcToPoint(Offset(size.width - 22, size.height), radius: const Radius.elliptical(10, 2))
      ..lineTo(4, size.height)
      ..arcToPoint(Offset(0, size.height - 4), radius: const Radius.circular(4));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
