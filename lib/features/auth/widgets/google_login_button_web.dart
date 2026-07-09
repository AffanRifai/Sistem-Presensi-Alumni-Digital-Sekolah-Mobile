import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget buildGoogleLoginButton({
  required bool isLoading,
  required VoidCallback onPressed,
}) {
  if (isLoading) {
    return const SizedBox(
      width: 220,
      height: 44,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }

  return SizedBox(
    width: 220,
    height: 44,
    child: web.renderButton(
      configuration: web.GSIButtonConfiguration(
        size: web.GSIButtonSize.large,
        type: web.GSIButtonType.standard,
        text: web.GSIButtonText.signinWith,
        shape: web.GSIButtonShape.pill,
        theme: web.GSIButtonTheme.outline,
      ),
    ),
  );
}
