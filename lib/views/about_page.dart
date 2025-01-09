import 'package:flutter/material.dart';
import 'package:ohnote/data/app_theme.dart';
import 'package:ohnote/view_components/header_buttons.dart';
import 'package:ohnote/tools/custom_toast.dart' as t;

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
                  padding: EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image(
                        height: 45.0,
                        width: 45.0,
                        image: AssetImage('assets/icon/icon.png'),
                      ),
                      Text('Version: 1.0.0'),
                      Text('Contact dev:'),
                      TextButton(
                          onPressed: () {
                            //TODO: copy to clipboard
                            t.showCustomToast('Email copied to clipboard', context);
                          },
                          child: Text('trendsappsdev@gmail.com')),
                      Text(
                        'Copyright © 2025 Trends Apps. OhNote is a trademark of Trends Apps. All rights reserved.',
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
