import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class ModernSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final List<Widget>? filters;

  const ModernSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.filters,
  });

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getPadding(context);
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: onClear,
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: Responsive.isMobile(context) ? 12 : 14,
              ),
            ),
            onChanged: onChanged,
          ),
          if (filters != null && filters!.isNotEmpty) ...[
            SizedBox(height: Responsive.isMobile(context) ? 8 : 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

