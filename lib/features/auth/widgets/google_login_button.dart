import 'package:flutter/material.dart';

import 'google_login_button_stub.dart'
    if (dart.library.html) 'google_login_button_web.dart'
    as google_button;

class GoogleLoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const GoogleLoginButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return google_button.buildGoogleLoginButton(
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }
}
