import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/font_size_service.dart';

class FontScaleWrapper extends StatelessWidget {
  final Widget child;

  const FontScaleWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeService>(
      builder: (context, fontSizeService, _) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(fontSizeService.currentScale),
          ),
          child: child,
        );
      },
    );
  }
}
