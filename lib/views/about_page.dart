import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohnote/data/app_theme.dart';
import 'package:ohnote/tools/single_async.dart';
import 'package:ohnote/view_components/header_buttons.dart';
import 'package:ohnote/tools/custom_toast.dart' as t;

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const email = 'trendsappsdev@gmail.com';

  void _copyToClipboard(BuildContext context) {
    runFirst(() async {
      await Clipboard.setData(const ClipboardData(text: email));
      if (context.mounted) {
        t.showCustomToast('Email copied to clipboard', context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.current.darkTheme,
      child: Scaffold(
        backgroundColor: AppTheme.current.appIconColor,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Image(
                        height: 100.0,
                        width: 100.0,
                        image: AssetImage('assets/icon/icon.png'),
                      ),
                      const Text('Version: 1.0.0'),
                      const SizedBox(height: 20.0),
                      const Text('Contact dev:'),
                      TextButton(
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0)),
                          minimumSize: WidgetStateProperty.all(Size.zero),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _copyToClipboard(context),
                        onLongPress: () => _copyToClipboard(context),
                        child: const Text(email),
                      ),
                      const SizedBox(height: 20.0),
                      const Text(
                        '© 2025 Trends Apps. OhNote is a trademark of Trends Apps. All rights reserved.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  tooltip: HeaderButtonDetails.back.caption,
                  icon: Icon(HeaderButtonDetails.back.icon),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
