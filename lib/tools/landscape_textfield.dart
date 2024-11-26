import 'package:flutter/material.dart';

class LandscapeTextField extends StatefulWidget {
  const LandscapeTextField({
    super.key,
    required this.textFieldBuilder,
    this.controller,
    this.focusNode,
  });

  final TextField Function(TextEditingController controller, FocusNode focusNode, bool readOnly) textFieldBuilder;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  static InputDecoration? inputDecoration;

  @override
  State<LandscapeTextField> createState() => _LandscapeTextFieldState();
}

class _LandscapeTextFieldState extends State<LandscapeTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  TextField? _textField;
  bool overlayOpened = false;

  @override
  void initState() {
    _controller = widget.controller != null ? widget.controller! : TextEditingController();
    _focusNode = widget.focusNode != null ? widget.focusNode! : FocusNode();
    _focusNode.addListener(_openOverlay);
    super.initState();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.removeListener(_openOverlay);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        //"orientation" variable doesn't work in some scenarios
        if (!overlayOpened) {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _openOverlay());
        }
        var readOnly = MediaQuery.of(context).orientation == Orientation.landscape;
        _textField = widget.textFieldBuilder(_controller, _focusNode, readOnly);
        assert(_textField!.showCursor == true);
        assert(_textField!.controller == _controller);
        assert(_textField!.focusNode == _focusNode);
        assert(_textField!.readOnly == readOnly);
        return _textField!;
      },
    );
  }

  void _openOverlay() {
    if (!overlayOpened && mounted && MediaQuery.of(context).orientation == Orientation.landscape && _textField?.focusNode!.hasFocus == true) {
      overlayOpened = true;
      _focusNode.removeListener(_openOverlay);
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return _LandscapeTextFieldOverlay(textField: _textField!);
          },
        ),
      ).whenComplete(() {
        if (mounted && MediaQuery.of(context).orientation == Orientation.landscape) {
          _focusNode.unfocus();
        }
        overlayOpened = false;
        _focusNode.addListener(_openOverlay);
      });
    }
  }
}

class _LandscapeTextFieldOverlay extends StatefulWidget {
  const _LandscapeTextFieldOverlay({required this.textField});

  final TextField textField;

  @override
  State<_LandscapeTextFieldOverlay> createState() => __LandscapeTextFieldOverlayState();
}

class __LandscapeTextFieldOverlayState extends State<_LandscapeTextFieldOverlay> {
  bool isPopping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            //"orientation" variable doesn't work in some scenarios
            if (!isPopping && MediaQuery.of(context).orientation == Orientation.portrait) {
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                isPopping = true;
                Navigator.pop(context);
              });
            }
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      keyboardType: widget.textField.keyboardType,
                      controller: widget.textField.controller,
                      maxLines: widget.textField.keyboardType == TextInputType.multiline ? null : 1,
                      expands: widget.textField.keyboardType == TextInputType.multiline,
                      maxLength: widget.textField.maxLength,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: LandscapeTextField.inputDecoration ?? const InputDecoration(),
                      onChanged: (value) {
                        widget.textField.onChanged?.call(value);
                      },
                      onSubmitted: (value) {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('DONE'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
