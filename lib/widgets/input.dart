import 'package:flutter/material.dart';

class Input extends StatefulWidget {
  const Input({
    super.key,
    required this.icon,
    required this.hint,
    this.obsecure,
    required this.editingController,
    this.enable = true,
    this.onTapBox,
    this.readOnly = false,
    this.keyboardType,
  });
  final String icon;
  final String hint;
  final bool? obsecure;
  final TextEditingController editingController;
  final bool enable;
  final VoidCallback? onTapBox;
  final bool readOnly;
  final TextInputType? keyboardType;

  @override
  State<Input> createState() => _InputState();
}

class _InputState extends State<Input> {
  late bool _isObscure;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obsecure ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTapBox,
      child: TextField(
        controller: widget.editingController,
        keyboardType: widget.keyboardType,
        readOnly: widget.readOnly,
        style: TextStyle(
          height: 1.7,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xff070623),
        ),
        obscureText: _isObscure,
        decoration: InputDecoration(
          enabled: widget.enable,
          hintText: widget.hint,
          hintStyle: const TextStyle(
            height: 1.7,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xff838384),
          ),
          fillColor: Color(0xffffffff),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          isDense: true,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: Color(0xff4A1DFF), width: 2),
          ),
          prefixIcon: UnconstrainedBox(
            alignment: Alignment(0.5, 0),
            child: Image.asset(widget.icon, width: 24, height: 24),
          ),
          suffixIcon: (widget.obsecure ?? false)
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      _isObscure
                          ? 'assets/eye_hidden.png'
                          : 'assets/eye.png', // mata terbuka
                      width: 22,
                      height: 22,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
