import 'dart:async';
import 'package:elite_wallet/store/settings_store.dart';
import 'package:ew_core/crypto_currency.dart';
import 'package:ew_core/transaction_priority.dart';
import 'package:ew_haven/haven_transaction_creation_credentials.dart';
import 'package:ew_core/monero_amount_format.dart';
import 'package:ew_haven/haven_transaction_creation_exception.dart';
import 'package:ew_haven/haven_transaction_info.dart';
import 'package:ew_haven/haven_wallet_addresses.dart';
import 'package:ew_core/monero_wallet_utils.dart';
import 'package:ew_haven/api/structs/pending_transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:ew_haven/api/transaction_history.dart'
    as haven_transaction_history;
//import 'package:ew_haven/wallet.dart';
import 'package:ew_haven/api/wallet.dart' as haven_wallet;
import 'package:ew_haven/api/transaction_history.dart' as transaction_history;
import 'package:ew_haven/api/monero_output.dart';
import 'package:ew_haven/pending_haven_transaction.dart';
import 'package:ew_core/monero_wallet_keys.dart';
import 'package:ew_core/monero_balance.dart';
import 'package:ew_haven/haven_transaction_history.dart';
import 'package:ew_core/account.dart';
import 'package:ew_core/pending_transaction.dart';
import 'package:ew_core/wallet_base.dart';
import 'package:ew_core/sync_status.dart';
import 'package:ew_core/wallet_info.dart';
import 'package:ew_core/node.dart';
import 'package:ew_core/monero_transaction_priority.dart';
import 'package:ew_haven/haven_balance.dart';
import 'package:ew_core/port_redirector.dart';

part 'haven_wallet.g.dart';

const moneroBlockSize = 1000;

class HavenWallet = HavenWalletBase with _$HavenWallet;

abstract class HavenWalletBase extends WalletBase<MoneroBalance,
    HavenTransactionHistory, HavenTransactionInfo> with Store {
  HavenWalletBase({required WalletInfo walletInfo})
      : balance = ObservableMap.of(getHavenBalance(accountIndex: 0)),
        _isTransactionUpdating = false,
        _hasSyncAfterStartup = false,
        walletAddresses = HavenWalletAddresses(walletInfo),
        syncStatus = NotConnectedSyncStatus(),
        super(walletInfo) {
    transactionHistory = HavenTransactionHistory();
    _onAccountChangeReaction = reaction((_) => walletAddresses.account,
            (Account? account) {
      if (account == null) {
        return;
      }
      balance.addAll(getHavenBalance(accountIndex: account.id));
      walletAddresses.updateSubaddressList(accountIndex: account.id);
    });
  }

  static const int _autoSaveInterval = 30;

  @override
  HavenWalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  ObservableMap<CryptoCurrency, MoneroBalance> balance;

  @override
  String get seed => haven_wallet.getSeed();

  @override
  MoneroWalletKeys get keys => MoneroWalletKeys(
      privateSpendKey: haven_wallet.getSecretSpendKey(),
      privateViewKey: haven_wallet.getSecretViewKey(),
      publicSpendKey: haven_wallet.getPublicSpendKey(),
      publicViewKey: haven_wallet.getPublicViewKey());

  static const connectionTimeout = Duration(seconds: 5);

  PortRedirector? _portRedirector;
  haven_wallet.SyncListener? _listener;
  ReactionDisposer? _onAccountChangeReaction;
  bool _isTransactionUpdating;
  bool _hasSyncAfterStartup;
  Timer? _autoSaveTimer;

  Future<void> init() async {
    await walletAddresses.init();
    balance.addAll(getHavenBalance(accountIndex: walletAddresses.account?.id ?? 0));
    _setListeners();
    await updateTransactions();

    if (walletInfo.isRecovery) {
      haven_wallet.setRecoveringFromSeed(isRecovery: walletInfo.isRecovery);

      if (haven_wallet.getCurrentHeight() <= 1) {
        haven_wallet.setRefreshFromBlockHeight(
            height: walletInfo.restoreHeight);
      }
    }

    _autoSaveTimer = Timer.periodic(
       Duration(seconds: _autoSaveInterval),
       (_) async => await save());
  }

  @override
  Future<void>? updateBalance() => null;

  @override
  void close() {
    _listener?.stop();
    _onAccountChangeReaction?.reaction.dispose();
    _autoSaveTimer?.cancel();
  }

  @override
  Future<void> connectToNode({required Node node,
                              required SettingsStore settingsStore}) async {
    String host = node.uri.host;
    int port = node.uri.port;
    PortRedirector portRedirector = await PortRedirector.start(
      settingsStore, host, port, timeout: connectionTimeout);
    host = portRedirector.host;
    port = portRedirector.port;
    _portRedirector = portRedirector;
    String uriString = host + ":" + port.toString();

    try {
      syncStatus = ConnectingSyncStatus();
      await haven_wallet.setupNode(
          address: uriString,
          login: node.login,
          password: node.password,
          useSSL: node.useSSL ?? false,
          isLightWallet: false); // FIXME: hardcoded value

      haven_wallet.setTrustedDaemon(node.trusted);
      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
      print(e);
    }
  }

  @override
  Future<void> startSync() async {
    try {
      _setInitialHeight();
    } catch (_) {}

    try {
      syncStatus = AttemptingSyncStatus();
      haven_wallet.startRefresh();
      _setListeners();
      _listener?.start();
    } catch (e) {
      syncStatus = FailedSyncStatus();
      print(e);
      rethrow;
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final _credentials = credentials as HavenTransactionCreationCredentials;
    final outputs = _credentials.outputs;
    final hasMultiDestination = outputs.length > 1;
    final assetType = CryptoCurrency.fromString(_credentials.assetType.toLowerCase());
    final balances = getHavenBalance(accountIndex: walletAddresses.account!.id);
    final unlockedBalance = balances[assetType]!.unlockedBalance;

    PendingTransactionDescription pendingTransactionDescription;

    if (!(syncStatus is SyncedSyncStatus)) {
      throw HavenTransactionCreationException('The wallet is not synced.');
    }

    if (hasMultiDestination) {
      if (outputs.any((item) => item.sendAll
          || (item.formattedCryptoAmount ?? 0) <= 0)) {
        throw HavenTransactionCreationException('You do not have enough coins to send this amount.');
      }

      final int totalAmount = outputs.fold(0, (acc, value) =>
          acc + (value.formattedCryptoAmount ?? 0));

      if (unlockedBalance < totalAmount) {
        throw HavenTransactionCreationException('You do not have enough coins to send this amount.');
      }

      final moneroOutputs = outputs.map((output) =>
          MoneroOutput(
              address: output.address,
              amount: output.cryptoAmount!.replaceAll(',', '.')))
          .toList();

      pendingTransactionDescription =
      await transaction_history.createTransactionMultDest(
          outputs: moneroOutputs,
          priorityRaw: _credentials.priority.serialize(),
          accountIndex: walletAddresses.account!.id);
    } else {
      final output = outputs.first;
      final address = output.isParsedAddress && (output.extractedAddress?.isNotEmpty ?? false)
          ? output.extractedAddress!
          : output.address;
      final amount = output.sendAll
          ? null
          : output.cryptoAmount!.replaceAll(',', '.');
      final int? formattedAmount = output.sendAll
          ? null
          : output.formattedCryptoAmount;

      if ((formattedAmount != null && unlockedBalance < formattedAmount) ||
          (formattedAmount == null && unlockedBalance <= 0)) {
        final formattedBalance = moneroAmountToString(amount: unlockedBalance);

        throw HavenTransactionCreationException(
            'You do not have enough unlocked balance. Unlocked: $formattedBalance. Transaction amount: ${output.cryptoAmount}.');
      }

      pendingTransactionDescription =
      await transaction_history.createTransaction(
          address: address,
          assetType: _credentials.assetType,
          amount: amount,
          priorityRaw: _credentials.priority.serialize(),
          accountIndex: walletAddresses.account!.id);
    }

    return PendingHavenTransaction(pendingTransactionDescription, assetType);
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    // FIXME: hardcoded value;

    if (priority is MoneroTransactionPriority) {
      switch (priority) {
        case MoneroTransactionPriority.slow:
          return 24590000;
        case MoneroTransactionPriority.automatic:
          return 123050000;
        case MoneroTransactionPriority.medium:
          return 245029999;
        case MoneroTransactionPriority.fast:
          return 614530000;
        case MoneroTransactionPriority.fastest:
          return 26021600000;
      }
    }

    return 0;
  }

  @override
  Future<void> save() async {
    await walletAddresses.updateAddressesInBox();
    await backupWalletFiles(name);
    await haven_wallet.store();
  }

  @override
  Future<void> changePassword(String password) async {
    haven_wallet.setPasswordSync(password);
  }

  Future<int> getNodeHeight() async => haven_wallet.getNodeHeight();

  Future<bool> isConnected() async => haven_wallet.isConnected();

  Future<void> setAsRecovered() async {
    walletInfo.isRecovery = false;
    await walletInfo.save();
  }

  @override
  Future<void> rescan({required int height}) async {
    walletInfo.restoreHeight = height;
    walletInfo.isRecovery = true;
    haven_wallet.setRefreshFromBlockHeight(height: height);
    haven_wallet.rescanBlockchainAsync();
    await startSync();
    _askForUpdateBalance();
    walletAddresses.accountList.update();
    await _askForUpdateTransactionHistory();
    await save();
    await walletInfo.save();
  }

  String getTransactionAddress(int accountIndex, int addressIndex) =>
      haven_wallet.getAddress(
          accountIndex: accountIndex,
          addressIndex: addressIndex);

  @override
  Future<Map<String, HavenTransactionInfo>> fetchTransactions() async {
    haven_transaction_history.refreshTransactions();
    return _getAllTransactions(null).fold<Map<String, HavenTransactionInfo>>(
        <String, HavenTransactionInfo>{},
        (Map<String, HavenTransactionInfo> acc, HavenTransactionInfo tx) {
      acc[tx.id] = tx;
      return acc;
    });
  }

  Future<void> updateTransactions() async {
    try {
      if (_isTransactionUpdating) {
        return;
      }

      _isTransactionUpdating = true;
      final transactions = await fetchTransactions();
      transactionHistory.addMany(transactions);
      await transactionHistory.save();
      _isTransactionUpdating = false;
    } catch (e) {
      print(e);
      _isTransactionUpdating = false;
    }
  }

  List<HavenTransactionInfo> _getAllTransactions(dynamic _) => haven_transaction_history
          .getAllTransations()
          .map((row) => HavenTransactionInfo.fromRow(row))
          .toList();

  void _setListeners() {
    _listener?.stop();
    _listener = haven_wallet.setListeners(_onNewBlock, _onNewTransaction);
  }

  void _setInitialHeight() {
    if (walletInfo.isRecovery) {
      return;
    }

    final currentHeight = haven_wallet.getCurrentHeight();

    if (currentHeight <= 1) {
      final height = _getHeightByDate(walletInfo.date);
      haven_wallet.setRecoveringFromSeed(isRecovery: true);
      haven_wallet.setRefreshFromBlockHeight(height: height);
    }
  }

  int _getHeightDistance(DateTime date) {
    final distance =
        DateTime.now().millisecondsSinceEpoch - date.millisecondsSinceEpoch;
    final daysTmp = (distance / 86400).round();
    final days = daysTmp < 1 ? 1 : daysTmp;

    return days * 1000;
  }

  int _getHeightByDate(DateTime date) {
    final nodeHeight = haven_wallet.getNodeHeightSync();
    final heightDistance = _getHeightDistance(date);

    if (nodeHeight <= 0) {
      return 0;
    }

    return nodeHeight - heightDistance;
  }

  void _askForUpdateBalance() =>
      balance.addAll(getHavenBalance(accountIndex: walletAddresses.account!.id));

  Future<void> _askForUpdateTransactionHistory() async =>
      await updateTransactions();

  void _onNewBlock(int height, int blocksLeft, double ptc) async {
    try {
      if (walletInfo.isRecovery) {
        await _askForUpdateTransactionHistory();
        _askForUpdateBalance();
        walletAddresses.accountList.update();
      }

      if (blocksLeft < 1000) {
        await _askForUpdateTransactionHistory();
        _askForUpdateBalance();
        walletAddresses.accountList.update();
        syncStatus = SyncedSyncStatus();

        if (!_hasSyncAfterStartup) {
           _hasSyncAfterStartup = true;
           await save();
         }

        if (walletInfo.isRecovery) {
          await setAsRecovered();
        }
      } else {
        syncStatus = SyncingSyncStatus(blocksLeft, ptc);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void _onNewTransaction() async {
    try {
      await _askForUpdateTransactionHistory();
      _askForUpdateBalance();
      await Future<void>.delayed(Duration(seconds: 1));
    } catch (e) {
      print(e.toString());
    }
  }
}
