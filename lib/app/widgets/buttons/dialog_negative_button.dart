import 'package:flutter/material.dart';

import '../../utils/utils.dart';

class NegativeButton extends StatelessWidget {
  const NegativeButton({
    required this.text,
    required this.onPressed,
    required this.buttonsAspectRatio,
    this.buttonConstrains = Dimensions.sizeConstrainsDialogAction,
    this.focusNode,
    Key? key,
  }) : super(key: key);

  final String? text;
  final GestureTapCallback? onPressed;
  final double buttonsAspectRatio;
  final BoxConstraints buttonConstrains;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomRight,
            child: AspectRatio(
              aspectRatio: buttonsAspectRatio,
              child: Container(
                margin: Dimensions.marginDialogNegativeButton,
                child: RawMaterialButton(
                  focusNode: focusNode,
                  onPressed: onPressed,
                  child: Text((text ?? '').toUpperCase()),
                  constraints: buttonConstrains,
                  elevation: Dimensions.elevationDialogAction,
                  textStyle: Dimensions.textStyleDialogNegativeButton,
                ),
              ),
            ),
          ),
        ),
      ],
    ));
  }
}
