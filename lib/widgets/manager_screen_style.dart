import 'package:flutter/material.dart';

class ManagerScreenStyle {
  static const pageBg = Color(0xFF1C2230);
  static const panelBg = Color(0xFF202738);
  static const fieldBg = Color(0xFF252B3C);
  static const tileBg = Color(0xFF1B2335);
  static const cyan = Color(0xFF84E5F4);
  static const muted = Color(0xFFA9AFBE);
  static const danger = Color(0xFFFF675E);
}

class ManagerFormShell extends StatelessWidget {
  final String title;
  final Widget child;

  const ManagerFormShell({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class ManagerSectionPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const ManagerSectionPanel({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        MediaQuery.sizeOf(context).width < 430 ? 14.0 : 20.0;

    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
      decoration: BoxDecoration(
        color: ManagerScreenStyle.panelBg.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ManagerScreenStyle.cyan,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(
                color: ManagerScreenStyle.muted,
                fontSize: 16,
                letterSpacing: 0,
              ),
            ),
          ],
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class ManagerFieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const ManagerFieldLabel(this.label, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        children: [
          if (required)
            const TextSpan(
              text: '*',
              style: TextStyle(color: ManagerScreenStyle.danger),
            ),
        ],
      ),
    );
  }
}

InputDecoration managerFieldDecoration({
  Widget? suffixIcon,
  String? hintText,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Color(0xFFE8ECF5)),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: ManagerScreenStyle.fieldBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ManagerScreenStyle.cyan, width: 1.4),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
}

class ManagerSelectBox<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T item) labelFor;
  final ValueChanged<T?> onChanged;

  const ManagerSelectBox({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: ManagerScreenStyle.fieldBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          dropdownColor: ManagerScreenStyle.fieldBg,
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          hint: Text(
            hint,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelFor(item),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class ManagerActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool secondary;
  final bool danger;
  final double? width;

  const ManagerActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.danger = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = danger
        ? const [Color(0xFFFF5B5F), Color(0xFFFF4A63)]
        : secondary
            ? const [Color(0xFF025769), Color(0xFF4E4AF2)]
            : const [Color(0xFF34C8E8), Color(0xFF4E4AF2)];

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
          label: Text(text),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
