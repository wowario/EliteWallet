import 'dart:async';
import 'package:elite_wallet/exchange/changenow/changenow_exchange_provider.dart';
import 'package:elite_wallet/exchange/majesticbank/majesticbank_exchange_provider.dart';
import 'package:elite_wallet/exchange/xchangeme/xchangeme_exchange_provider.dart';
import 'package:elite_wallet/exchange/exch/exch_exchange_provider.dart';
import 'package:elite_wallet/exchange/exchange_provider.dart';
import 'package:elite_wallet/exchange/exchange_provider_description.dart';
import 'package:elite_wallet/exchange/morphtoken/morphtoken_exchange_provider.dart';
import 'package:elite_wallet/exchange/sideshift/sideshift_exchange_provider.dart';
import 'package:elite_wallet/exchange/simpleswap/simpleswap_exchange_provider.dart';
import 'package:elite_wallet/exchange/trade.dart';
import 'package:elite_wallet/exchange/trocador/trocador_exchange_provider.dart';
import 'package:elite_wallet/exchange/xmrto/xmrto_exchange_provider.dart';
import 'package:elite_wallet/store/settings_store.dart';
import 'package:elite_wallet/utils/date_formatter.dart';
import 'package:elite_wallet/utils/show_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:elite_wallet/generated/i18n.dart';
import 'package:elite_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:elite_wallet/src/screens/trade_details/track_trade_list_item.dart';
import 'package:elite_wallet/src/screens/trade_details/trade_details_list_card.dart';
import 'package:elite_wallet/src/screens/trade_details/trade_details_status_item.dart';
import 'package:elite_wallet/store/settings_store.dart';
import 'package:ew_core/format_amount.dart';
part 'trade_details_view_model.g.dart';

class TradeDetailsViewModel = TradeDetailsViewModelBase with _$TradeDetailsViewModel;

abstract class TradeDetailsViewModelBase with Store {
  TradeDetailsViewModelBase({
    required Trade tradeForDetails,
    required this.trades,
    required this.settingsStore,
  })  : items = ObservableList<StandartListItem>(),
        trade = tradeForDetails {
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

    items = ObservableList<StandartListItem>();

    _updateItems();

    _updateTrade();

    timer = Timer.periodic(Duration(seconds: 20), (_) async => _updateTrade());
  }

  final Box<Trade> trades;

  @observable
  Trade trade;

  @observable
  ObservableList<StandartListItem> items;

  ExchangeProvider? _provider;

  Timer? timer;

  final SettingsStore settingsStore;

  @action
  Future<void> _updateTrade() async {
    try {
      final updatedTrade = await _provider!.findTradeById(id: trade.id);

      if (updatedTrade.createdAt == null && trade.createdAt != null) {
        updatedTrade.createdAt = trade.createdAt;
      }

      if (updatedTrade.expiredAt == null && trade.expiredAt != null) {
        updatedTrade.expiredAt = trade.expiredAt;
      }

      trade = updatedTrade;

      _updateItems();
    } catch (e) {
      print(e.toString());
    }
  }

  void _updateItems() {
    final dateFormat = DateFormatter.withCurrentLocal(reverse: true);

    items.clear();

    items.add(
        DetailsListStatusItem(title: S.current.trade_details_state, value: trade.state.toString()));

    items.add(TradeDetailsListCardItem.tradeDetails(
      id: trade.id,
      createdAt: trade.createdAt != null ? dateFormat.format(trade.createdAt!) : '',
      from: trade.from,
      to: trade.to,
      onTap: (BuildContext context) {
        Clipboard.setData(ClipboardData(text: '${trade.id}'));
        showBar<void>(context, S.of(context).copied_to_clipboard);
      },
    ));

    items.add(StandartListItem(
        title: S.current.trade_details_provider, value: trade.provider.toString()));

    if (trade.provider == ExchangeProviderDescription.changeNow) {
      final buildURL = 'https://changenow.io/exchange/txs/${trade.id.toString()}';
      items.add(TrackTradeListItem(
          title: 'Track',
          value: buildURL,
          onTap: () {
            {};
          }));
    }

    if (trade.provider == ExchangeProviderDescription.majesticBank) {
      if (trade.amount != null) {
        items.add(TrackTradeListItem(
            title: 'Send amount',
            value: '${formatAmount(trade.amount.toString())} '
                   '${trade.from.toString()}',
            onTap: () {
              {};
            }));
      }

      if (trade.receiveAmount != null) {
        items.add(TrackTradeListItem(
            title: 'Receive amount',
            value: '${formatAmount(trade.receiveAmount.toString())} '
                   '${trade.to.toString()}',
            onTap: () {
              {};
            }));
      }

      if (trade.received != null) {
        items.add(TrackTradeListItem(
            title: 'Received',
            value: '${formatAmount(trade.received.toString())} '
                   '${trade.from.toString()}',
            onTap: () {
              {};
            }));
      }

      if (trade.confirmed != null) {
        items.add(TrackTradeListItem(
            title: 'Confirmed',
            value: '${formatAmount(trade.confirmed.toString())} '
                   '${trade.from.toString()}',
            onTap: () {
              {};
            }));
      }
    }

    if (trade.provider == ExchangeProviderDescription.xchangeme) {
      if (trade.amount != null) {
        items.add(TrackTradeListItem(
            title: 'Send amount',
            value: '${formatAmount(trade.amount.toString())} '
                   '${trade.from.toString()}',
            onTap: () {
              {};
            }));
      }
    }

    if (trade.provider == ExchangeProviderDescription.sideShift) {
      final buildURL = 'https://sideshift.ai/orders/${trade.id.toString()}';
      items.add(TrackTradeListItem(
          title: 'Track', value: buildURL, onTap: () => {}));
    }

    if (trade.provider == ExchangeProviderDescription.simpleSwap) {
      final buildURL = 'https://simpleswap.io/exchange?id=${trade.id.toString()}';
      items.add(TrackTradeListItem(title: 'Track', value: buildURL, onTap: () => {}));
    }

    if (trade.provider == ExchangeProviderDescription.trocador) {
      final buildURL = 'https://trocador.app/en/checkout/${trade.id.toString()}';
      items.add(TrackTradeListItem(title: 'Track', value: buildURL, onTap: () => {}));

      items.add(StandartListItem(
          title: '${trade.providerName} ${S.current.id.toUpperCase()}',
          value: trade.providerId ?? ''));

      if (trade.password != null && trade.password!.isNotEmpty)
        items.add(StandartListItem(
            title: '${trade.providerName} ${S.current.password}', value: trade.password ?? ''));
    }
  }
}
