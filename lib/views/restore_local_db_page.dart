import 'package:flutter/material.dart';
import 'package:ohnote/tools/single_async.dart' as a;

// *************************
// *** Page not used yet ***
// *************************
class RestoreLocalDbPage extends StatelessWidget {
  const RestoreLocalDbPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Expanded(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'Existing data found in local storage. Do you want to restore the found data?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  children: [
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        a.runFirst(() async {
                          //await AppData.restoreDb();
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        });
                      },
                      child: const Text('RESTORE'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('CANCEL'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
