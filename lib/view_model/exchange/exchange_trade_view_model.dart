import 'dart:async';
import 'package:elite_wallet/exchange/sideshift/sideshift_exchange_provider.dart';
import 'package:elite_wallet/exchange/simpleswap/simpleswap_exchange_provider.dart';
import 'package:elite_wallet/exchange/trocador/trocador_exchange_provider.dart';
import 'package:ew_core/wallet_base.dart';
import 'package:ew_core/crypto_currency.dart';
import 'package:elite_wallet/exchange/changenow/changenow_exchange_provider.dart';
import 'package:elite_wallet/exchange/majesticbank/majesticbank_exchange_provider.dart';
import 'package:elite_wallet/exchange/xchangeme/xchangeme_exchange_provider.dart';
import 'package:elite_wallet/exchange/exch/exch_exchange_provider.dart';
import 'package:elite_wallet/exchange/exchange_provider.dart';
import 'package:elite_wallet/exchange/exchange_provider_description.dart';
import 'package:elite_wallet/exchange/morphtoken/morphtoken_exchange_provider.dart';
import 'package:elite_wallet/exchange/trade.dart';
import 'package:elite_wallet/exchange/xmrto/xmrto_exchange_provider.dart';
import 'package:elite_wallet/store/dashboard/trades_store.dart';
import 'package:elite_wallet/view_model/send/send_view_model.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:elite_wallet/src/screens/exchange_trade/exchange_trade_item.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:elite_wallet/store/settings_store.dart';

part 'exchange_trade_view_model.g.dart';

class ExchangeTradeViewModel = ExchangeTradeViewModelBase with _$ExchangeTradeViewModel;

abstract class ExchangeTradeViewModelBase with Store {
  ExchangeTradeViewModelBase(
      {required this.wallet,
      required this.trades,
      required this.tradesStore,
      required this.sendViewModel,
      required this.settingsStore})
      : trade = tradesStore.trade!,
        isSendable = tradesStore.trade!.from == wallet.currency ||
            tradesStore.trade!.provider == ExchangeProviderDescription.xmrto,
        items = ObservableList<ExchangeTradeItem>() {
    switch (trade.provider) {
      case ExchangeProviderDescription.xmrto:
        _provider = XMRTOExchangeProvider(settingsStore);
        break;
      case ExchangeProviderDescription.changeNow:
        _provider = ChangeNowExchangeProvider(settingsStore);
        break;
      case ExchangeProviderDescription.majesticBank:
        _provider = MajesticBankExchangeProvider(settingsStore);
        break;
      case ExchangeProviderDescription.xchangeme:
        _provider = XchangeMeExchangeProvider(settingsStore);
        break;
      case ExchangeProviderDescription.exch:
        _provider = ExchExchangeProvider(settingsStore);
        break;
      case ExchangeProviderDescription.morphToken:
        _provider = MorphTokenExchangeProvider(settingsStore, trades: trades);
        break;
      case ExchangeProviderDescription.sideShift:
        _provider = SideShiftExchangeProvider(settingsStore);
        break;
      case ExchangeProviderDescription.simpleSwap:
        _provider = SimpleSwapExchangeProvider(settingsStore);
        break;
        case ExchangeProviderDescription.trocador:
        _provider = TrocadorExchangeProvider(settingsStore);
        break;
    }

    _updateItems();
    _updateTrade();
    timer = Timer.periodic(Duration(seconds: 20), (_) async => _updateTrade());
  }

  final WalletBase wallet;
  final Box<Trade> trades;
  final TradesStore tradesStore;
  final SendViewModel sendViewModel;
  final SettingsStore settingsStore;

  @observable
  Trade trade;

  @observable
  bool isSendable;

  @computed
  String get extraInfo => trade.from == CryptoCurrency.xlm
      ? '\n\n' + S.current.xlm_extra_info
      : trade.from == CryptoCurrency.xrp
          ? '\n\n' + S.current.xrp_extra_info
          : '';

  @computed
  String get pendingTransactionFiatAmountValueFormatted => sendViewModel.isFiatDisabled
      ? ''
      : sendViewModel.pendingTransactionFiatAmount + ' ' + sendViewModel.fiat.title;

  @computed
  String get pendingTransactionFeeFiatAmountFormatted => sendViewModel.isFiatDisabled
      ? ''
      : sendViewModel.pendingTransactionFeeFiatAmount + ' ' + sendViewModel.fiat.title;

  @observable
  ObservableList<ExchangeTradeItem> items;

  ExchangeProvider? _provider;

  Timer? timer;

  @action
  Future confirmSending() async {
    if (!isSendable) {
      return;
    }

    sendViewModel.clearOutputs();
    final output = sendViewModel.outputs.first;
    output.address = trade.inputAddress ?? '';
    output.setCryptoAmount(trade.amount);
    await sendViewModel.createTransaction();
  }

  @action
  Future<void> _updateTrade() async {
    try {
      final updatedTrade = await _provider!.findTradeById(id: trade.id);

      if (updatedTrade.createdAt == null && trade.createdAt != null) {
        updatedTrade.createdAt = trade.createdAt;
      }

      trade = updatedTrade;

      _updateItems();
    } catch (e) {
      print(e.toString());
    }
  }

  void _updateItems() {
    final tagFrom = tradesStore.trade!.from.tag != null ? '${tradesStore.trade!.from.tag}' + ' ' : '';
    final tagTo = tradesStore.trade!.to.tag != null ? '${tradesStore.trade!.to.tag}' + ' ' : '';
    items.clear();
    items.add(ExchangeTradeItem(
        title: "${trade.provider.title} ${S.current.id}", data: '${trade.id}', isCopied: true));

    if (trade.extraId != null) {
      final title = trade.from == CryptoCurrency.xrp
          ? S.current.destination_tag
          : trade.from == CryptoCurrency.xlm
              ? S.current.memo
              : S.current.extra_id;

      items.add(ExchangeTradeItem(title: title, data: '${trade.extraId}', isCopied: false));
    }

    items.addAll([
      ExchangeTradeItem(title: S.current.amount, data: '${trade.amount}', isCopied: true),
      ExchangeTradeItem(
          title: S.current.send_to_this_address('${tradesStore.trade!.from}', tagFrom) + ':',
          data: trade.inputAddress ?? '',
          isCopied: true),
      ExchangeTradeItem(
          title: S.current.arrive_in_this_address('${tradesStore.trade!.to}', tagTo) + ':',
          data: trade.payoutAddress ?? '',
          isCopied: true),
    ]);
  }
}
