import 'package:flutter/material.dart';

/// Bundled branding works offline and stays readable in both app themes.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.compact = false, this.width});

  final bool compact;
  final double? width;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Image.asset(
        compact
            ? 'assets/brand/coxbazarbanglo-symbol.png'
            : 'assets/brand/coxbazarbanglo-logo.png',
        width: width ?? (compact ? 32 : 280),
        fit: BoxFit.contain,
        semanticLabel: 'Coxbazarbanglo',
      ),
    ),
  );
}
