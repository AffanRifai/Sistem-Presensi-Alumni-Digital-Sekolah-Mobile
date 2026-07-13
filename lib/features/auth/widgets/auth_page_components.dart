import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AuthUi {
  static const Color primary = Color(0xFF2F6FD0);
  static const Color text = Color(0xFF171717);
  static const Color muted = Color(0xFF737373);
  static const Color field = Color(0xFFF5F6F8);
  static const Color border = Color(0xFFE1E4E8);

  static InputDecoration inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 14),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: _border(Colors.transparent),
      enabledBorder: _border(Colors.transparent),
      focusedBorder: _border(primary),
      errorBorder: _border(const Color(0xFFD64545)),
      focusedErrorBorder: _border(const Color(0xFFD64545)),
    );
  }

  static OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }
}

class AuthPageBody extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBack;

  const AuthPageBody({super.key, required this.child, this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AuthBackButton(onPressed: onBack),
                ),
                const SizedBox(height: 32),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AuthBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed ?? () => Navigator.maybePop(context),
      customBorder: const CircleBorder(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AuthUi.border),
        ),
        child: const Icon(Icons.arrow_back_rounded, size: 21),
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 27,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: AuthUi.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: AuthUi.muted,
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AuthUi.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AuthUi.primary.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class AuthOtpInput extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onCompleted;

  const AuthOtpInput({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onCompleted,
  });

  @override
  State<AuthOtpInput> createState() => _AuthOtpInputState();
}

class _AuthOtpInputState extends State<AuthOtpInput> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller.text,
      validator: (_) {
        final value = widget.controller.text.trim();
        if (value.isEmpty) return 'Kode OTP wajib diisi.';
        if (value.length != 6) return 'Kode OTP harus 6 digit angka.';
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.enabled ? _focusNode.requestFocus : null,
              child: Stack(
                children: [
                  Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        field.didChange(value);
                        setState(() {});
                        if (value.length == 6) widget.onCompleted?.call(value);
                      },
                      decoration: const InputDecoration(counterText: ''),
                    ),
                  ),
                  IgnorePointer(
                    child: Row(
                      children: List.generate(6, (index) {
                        final value = widget.controller.text;
                        final digit = index < value.length ? value[index] : '';
                        final active =
                            _focusNode.hasFocus && index == value.length;
                        return Expanded(
                          child: Container(
                            height: 58,
                            margin: EdgeInsets.only(right: index == 5 ? 0 : 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AuthUi.field,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active
                                    ? AuthUi.primary
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              digit,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: AuthUi.text,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 7),
              Text(
                field.errorText!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFD64545)),
              ),
            ],
          ],
        );
      },
    );
  }
}
