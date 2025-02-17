import 'package:auto_size_text/auto_size_text.dart';
import 'package:elite_wallet/entities/qr_view_data.dart';
import 'package:elite_wallet/src/widgets/section_divider.dart';
import 'package:elite_wallet/utils/show_bar.dart';
import 'package:device_display_brightness/device_display_brightness.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:elite_wallet/src/screens/base_page.dart';
import 'package:elite_wallet/src/widgets/list_row.dart';
import 'package:elite_wallet/view_model/wallet_keys_view_model.dart';
import 'package:elite_wallet/routes.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WalletKeysPage extends BasePage {
  WalletKeysPage(this.walletKeysViewModel);

  @override
  String get title => walletKeysViewModel.title;

  final WalletKeysViewModel walletKeysViewModel;

  @override
  Widget trailing(BuildContext context) => IconButton(
      onPressed: () async {
        // Get the current brightness:
        final double brightness = await DeviceDisplayBrightness.getBrightness();
        final url = await walletKeysViewModel.url;

        // ignore: unawaited_futures
        DeviceDisplayBrightness.setBrightness(1.0);
        await Navigator.pushNamed(
          context,
          Routes.fullscreenQR,
          arguments: QrViewData(data: url.toString(), version: QrVersions.auto),
        );
        // ignore: unawaited_futures
        DeviceDisplayBrightness.setBrightness(brightness);
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      icon: Image.asset(
        'assets/images/qr_code_icon.png',
      ));

  @override
  Widget body(BuildContext context) {
    return Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                  color: Theme.of(context).accentTextTheme!.bodySmall!.color!,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AutoSizeText(
                        S.of(context).do_not_share_warning_text.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        style: TextStyle(
                          fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.red)),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 7,
          child: Container(
        padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
        child: Observer(
          builder: (_) {
            return ListView.separated(
                separatorBuilder: (context, index) => Container(
                      height: 1,
                      padding: EdgeInsets.only(left: 24),
                      color: Theme.of(context).accentTextTheme!.titleLarge!.backgroundColor!,
                      child: const SectionDivider(),
                    ),
                itemCount: walletKeysViewModel.items.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = walletKeysViewModel.items[index];

                  return GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: item.value));
                      showBar<void>(context, S.of(context).copied_key_to_clipboard(item.title));
                    },
                    child: ListRow(
                      title: item.title + ':',
                      value: item.value,
                    ),
                  );
                });
          },
        )))]);
  }
}
