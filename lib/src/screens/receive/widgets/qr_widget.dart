import 'package:elite_wallet/entities/qr_view_data.dart';
import 'package:elite_wallet/routes.dart';
import 'package:elite_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:elite_wallet/src/screens/receive/widgets/currency_input_field.dart';
import 'package:elite_wallet/utils/device_info.dart';
import 'package:elite_wallet/utils/show_bar.dart';
import 'package:elite_wallet/utils/show_pop_up.dart';
import 'package:device_display_brightness/device_display_brightness.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:elite_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:elite_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';

class QRWidget extends StatelessWidget {
  QRWidget({
    required this.addressListViewModel,
    required this.isLight,
    this.qrVersion,
    this.heroTag,
    required this.amountController,
    required this.formKey,
    this.amountTextFieldFocusNode,
  });

  final WalletAddressListViewModel addressListViewModel;
  final TextEditingController amountController;
  final FocusNode? amountTextFieldFocusNode;
  final GlobalKey<FormState> formKey;
  final bool isLight;
  final int? qrVersion;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final copyImage = Image.asset('assets/images/copy_address.png',
        color: Theme.of(context).textTheme!.titleMedium!.decorationColor!);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                S.of(context).qr_fullscreen,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .accentTextTheme!
                        .displayMedium!
                        .backgroundColor!),
              ),
            ),
            Row(
              children: <Widget>[
                Spacer(flex: 3),
                Observer(
                  builder: (_) => Flexible(
                    flex: 5,
                    child: GestureDetector(
                      onTap: () {
                        changeBrightnessForRoute(
                          () async {
                            await Navigator.pushNamed(context, Routes.fullscreenQR,
                                arguments: QrViewData(
                                  data: addressListViewModel.uri.toString(),
                                  heroTag: heroTag,
                                ));
                          },
                        );
                      },
                      child: Hero(
                        tag: Key(heroTag ?? addressListViewModel.uri.toString()),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 3,
                                  color: Theme.of(context)
                                      .accentTextTheme!
                                      .displayMedium!
                                      .backgroundColor!,
                                ),
                              ),
                              child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 3,
                                      color:Colors.white,
                                    ),
                                  ),
                                  child: QrImage(data: addressListViewModel.uri.toString())),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Spacer(flex: 3)
              ],
            ),
          ],
        ),
        Observer(builder: (_) {
          return Padding(
            padding: EdgeInsets.only(top: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Form(
                    key: formKey,
                    child: CurrencyInputField(
                      focusNode: amountTextFieldFocusNode,
                      controller: amountController,
                      onTapPicker: () => _presentPicker(context),
                      selectedCurrency: addressListViewModel.selectedCurrency,
                      isLight: isLight,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        Padding(
          padding: EdgeInsets.only(top: 20, bottom: 8),
          child: Builder(
            builder: (context) => Observer(
              builder: (context) => GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: addressListViewModel.address.address));
                  showBar<void>(context, S.of(context).copied_to_clipboard);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        addressListViewModel.address.address,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .accentTextTheme!
                                .displayMedium!
                                .backgroundColor!),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: copyImage,
                    )
                  ],
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  void _presentPicker(BuildContext context) async {
    await showPopUp<void>(
      builder: (_) => CurrencyPicker(
        selectedAtIndex: addressListViewModel.selectedCurrencyIndex,
        items: addressListViewModel.currencies,
        hintText: S.of(context).search_currency,
        onItemSelected: addressListViewModel.selectCurrency,
      ),
      context: context,
    );
    // update amount if currency changed
    addressListViewModel.changeAmount(amountController.text);
  }

  Future<void> changeBrightnessForRoute(Future<void> Function() navigation) async {
    // if not mobile, just navigate
    if (!DeviceInfo.instance.isMobile) {
      navigation();
      return;
    }

    // Get the current brightness:
    final brightness = await DeviceDisplayBrightness.getBrightness();

    // ignore: unawaited_futures
    DeviceDisplayBrightness.setBrightness(1.0);

    await navigation();

    // ignore: unawaited_futures
    DeviceDisplayBrightness.setBrightness(brightness);
  }
}
