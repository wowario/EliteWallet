import 'package:elite_wallet/src/screens/transaction_details/blockexplorer_list_item.dart';
import 'package:elite_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:elite_wallet/src/screens/transaction_details/textfield_list_item.dart';
import 'package:elite_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:elite_wallet/view_model/unspent_coins/unspent_coins_item.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:elite_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart';
import 'package:elite_wallet/view_model/unspent_coins/unspent_coins_switch_item.dart';
import 'package:ew_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher.dart';

part 'unspent_coins_details_view_model.g.dart';

class UnspentCoinsDetailsViewModel = UnspentCoinsDetailsViewModelBase
    with _$UnspentCoinsDetailsViewModel;

abstract class UnspentCoinsDetailsViewModelBase with Store {
  UnspentCoinsDetailsViewModelBase(
      {required this.unspentCoinsItem, required this.unspentCoinsListViewModel})
      : items = <TransactionDetailsListItem>[],
        isFrozen = unspentCoinsItem.isFrozen,
        note = unspentCoinsItem.note {
    items = [
      StandartListItem(title: S.current.transaction_details_amount, value: unspentCoinsItem.amount),
      StandartListItem(title: S.current.widgets_address, value: unspentCoinsItem.address),
      TextFieldListItem(
          title: S.current.note_tap_to_change,
          value: note,
          onSubmitted: (value) {
            unspentCoinsItem.note = value;
            unspentCoinsListViewModel.saveUnspentCoinInfo(unspentCoinsItem);
          }),
      UnspentCoinsSwitchItem(
          title: S.current.freeze,
          value: '',
          switchValue: () => isFrozen,
          onSwitchValueChange: (value) async {
            isFrozen = value;
            unspentCoinsItem.isFrozen = value;
            if (value) {
              unspentCoinsItem.isSending = !value;
            }
            await unspentCoinsListViewModel.saveUnspentCoinInfo(unspentCoinsItem);
          }),
      BlockExplorerListItem(
          title: S.current.view_in_block_explorer,
          value: _explorerDescription(unspentCoinsListViewModel.wallet.type),
          onTap: () {
            try {
              final url = Uri.parse(
                  _explorerUrl(unspentCoinsListViewModel.wallet.type, unspentCoinsItem.hash));
              return launchUrl(url);
            } catch (e) {}

          })
    ];
  }

  String _explorerUrl(WalletType type, String txId) {
    switch (type) {
      case WalletType.bitcoin:
        return 'https://ordinals.com/tx/${txId}';
      case WalletType.litecoin:
        return 'https://litecoin.earlyordies.com/tx/${txId}';
      default:
        return '';
    }
  }

  String _explorerDescription(WalletType type) {
    switch (type) {
      case WalletType.bitcoin:
        return S.current.view_transaction_on + 'Ordinals.com';
      case WalletType.litecoin:
        return S.current.view_transaction_on + 'Earlyordies.com';
      default:
        return '';
    }
  }

  @observable
  bool isFrozen;

  @observable
  String note;

  final UnspentCoinsItem unspentCoinsItem;
  final UnspentCoinsListViewModel unspentCoinsListViewModel;
  List<TransactionDetailsListItem> items;
}
