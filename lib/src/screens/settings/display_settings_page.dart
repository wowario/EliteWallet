import 'package:elite_wallet/entities/fiat_currency.dart';
import 'package:elite_wallet/entities/language_service.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:elite_wallet/src/screens/base_page.dart';
import 'package:elite_wallet/src/screens/settings/widgets/settings_choices_cell.dart';
import 'package:elite_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:elite_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:elite_wallet/themes/theme_base.dart';
import 'package:elite_wallet/themes/theme_list.dart';
import 'package:elite_wallet/utils/device_info.dart';
import 'package:elite_wallet/view_model/settings/choices_list_item.dart';
import 'package:elite_wallet/view_model/settings/display_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DisplaySettingsPage extends BasePage {
  DisplaySettingsPage(this._displaySettingsViewModel);

  @override
  String get title => S.current.display_settings;

  final DisplaySettingsViewModel _displaySettingsViewModel;

  @override
  Widget body(BuildContext context) {
    return Observer(builder: (_) {
      return Container(
        padding: EdgeInsets.only(top: 10),
        child: Column(
          children: [
            SettingsSwitcherCell(
            title: S.current.settings_display_balance,
            value:  _displaySettingsViewModel.shouldDisplayBalance,
            onValueChange: (_, bool value) {
               _displaySettingsViewModel.setShouldDisplayBalance(value);          
            }),
            //if (!isHaven) it does not work correctly
            if(!_displaySettingsViewModel.disabledFiatApiMode)
              SettingsPickerCell<FiatCurrency>(
                title: S.current.settings_currency,
                searchHintText: S.current.search_currency,
                items: FiatCurrency.all,
                selectedItem: _displaySettingsViewModel.fiatCurrency,
                onItemSelected: (FiatCurrency currency) => _displaySettingsViewModel.setFiatCurrency(currency),
                images: FiatCurrency.all.map((e) => Image.asset("assets/images/flags/${e.countryCode}.png")).toList(),
                isGridView: true,
                matchingCriteria: (FiatCurrency currency, String searchText) {
                  return currency.title.toLowerCase().contains(searchText) ||
                      currency.fullName.toLowerCase().contains(searchText);
                },
              ),
            SettingsPickerCell<String>(
              title: S.current.settings_change_language,
              searchHintText: S.current.search_language,
              items: LanguageService.list.keys.toList(),
              displayItem: (dynamic code) {
                return LanguageService.list[code] ?? '';
              },
              selectedItem: _displaySettingsViewModel.languageCode,
              onItemSelected: _displaySettingsViewModel.onLanguageSelected,
              images: LanguageService.list.keys
                  .map((e) => Image.asset("assets/images/flags/${LanguageService.localeCountryCode[e]}.png"))
                  .toList(),
              matchingCriteria: (String code, String searchText) {
                return LanguageService.list[code]?.toLowerCase().contains(searchText) ?? false;
              },
            ),
          ],
        ),
      );
    });
  }
}
