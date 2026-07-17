import 'package:flutter/material.dart';

import '../data/college_models.dart';

/// University logo fetched from its own domain's favicon; falls back to a
/// two-letter initials badge if the URL is missing or the image fails to
/// load. Ported from ilm-ai-mobile's components/college/CollegeLogo.tsx.
class CollegeLogo extends StatefulWidget {
  final College college;
  final double size;
  final double fontSize;

  const CollegeLogo({super.key, required this.college, this.size = 44, this.fontSize = 14});

  @override
  State<CollegeLogo> createState() => _CollegeLogoState();
}

class _CollegeLogoState extends State<CollegeLogo> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final src = collegeLogoUrl(widget.college);
    final radius = widget.size * 0.28;

    if (_failed || src == null) {
      return Container(
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFF0D3B4F), borderRadius: BorderRadius.circular(radius)),
        child: Text(
          collegeInitials(widget.college.name),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: widget.fontSize),
        ),
      );
    }

    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Image.network(
        src,
        width: widget.size * 0.72,
        height: widget.size * 0.72,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _failed = true);
          });
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
