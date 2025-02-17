import 'package:ew_core/wallet_type.dart';
import 'package:elite_wallet/src/widgets/validable_annotated_editable_text.dart';
import 'package:elite_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:elite_wallet/palette.dart';
import 'package:elite_wallet/core/seed_validator.dart';
import 'package:elite_wallet/src/widgets/primary_button.dart';
import 'package:elite_wallet/entities/mnemonic_item.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:flutter/widgets.dart';

class SeedWidget extends StatefulWidget {
  SeedWidget({
    Key? key,
    required this.language,
    required this.type,
    this.onSeedChange}) : super(key: key);

  final String language;
  final WalletType type;
  final void Function(String)? onSeedChange;

  @override
  SeedWidgetState createState() => SeedWidgetState(language, type);
}

class SeedWidgetState extends State<SeedWidget> {

  SeedWidgetState(String language, this.type)
      : controller = TextEditingController(),
        focusNode = FocusNode(),
        words = SeedValidator.getWordList(type: type, language: language),
        _showPlaceholder = false {
    focusNode.addListener(() {
      setState(() {
        if (!focusNode.hasFocus && controller.text.isEmpty) {
          _showPlaceholder = true;
        }

        if (focusNode.hasFocus) {
          _showPlaceholder = false;
        }
      });
    });
  }

  final TextEditingController controller;
  final FocusNode focusNode;
  final WalletType type;
  List<String> words;
  bool _showPlaceholder;

  String get text => controller.text;

  @override
  void initState() {
    super.initState();
    _showPlaceholder = true;
    controller.addListener(() => widget.onSeedChange?.call(text));
  }

  void changeSeedLanguage(String language) {
    setState(() {
      words = SeedValidator.getWordList(type: type, language: language);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
          Stack(children: [
            SizedBox(height: 35),
            if (_showPlaceholder)
              Positioned(
                  top: 10,
                  left: 0,
                  child: Text('Enter your seed',
                      style: TextStyle(
                          fontSize: 16.0, color: Theme.of(context).hintColor))),
            Padding(
                padding: EdgeInsets.only(right: 40, top: 10),
                child: ValidatableAnnotatedEditableText(
                  cursorColor: Colors.blue,
                  backgroundCursorColor: Colors.blue,
                  validStyle: TextStyle(
                      color: Theme.of(context)
                          .primaryTextTheme!
                          .titleLarge!
                          .color!,
                      backgroundColor: Colors.transparent,
                      fontWeight: FontWeight.normal,
                      fontSize: 16),
                  invalidStyle: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.normal,
                      backgroundColor: Colors.transparent),
                  focusNode: focusNode,
                  controller: controller,
                  words: words,
                  textStyle: TextStyle(
                      color: Theme.of(context)
                          .primaryTextTheme!
                          .titleLarge!
                          .color!,
                      backgroundColor: Colors.transparent,
                      fontWeight: FontWeight.normal,
                      fontSize: 16),
                )),
            Positioned(
                top: 0,
                right: 8,
                child: Container(
                    width: 32,
                    height: 32,
                    child: InkWell(
                      onTap: () async => _pasteText(),
                      child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Theme.of(context).hintColor,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6))),
                          child: Image.asset('assets/images/paste_ios.png',
                              color: Theme.of(context)
                                  .primaryTextTheme!
                                  .headlineMedium!
                                  .decorationColor!)),
                    )))
          ]),
          Container(
              margin: EdgeInsets.only(top: 15),
              height: 1.0,
              color: Theme.of(context)
                  .primaryTextTheme!
                  .titleLarge!
                  .backgroundColor!),
        ]));
  }

  Future<void> _pasteText() async {
    final value = await Clipboard.getData('text/plain');

    if (value?.text?.isNotEmpty ?? false) {
      setState(() {
        _showPlaceholder = false;
        controller.text = value!.text!;
      });
    }
  }
}
