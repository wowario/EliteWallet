import 'package:elite_wallet/view_model/restore/restore_wallet.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:elite_wallet/monero/monero.dart';
import 'package:elite_wallet/store/app_store.dart';
import 'package:ew_core/wallet_base.dart';
import 'package:elite_wallet/core/wallet_creation_service.dart';
import 'package:ew_core/wallet_credentials.dart';
import 'package:ew_core/wallet_info.dart';
import 'package:ew_core/wallet_type.dart';
import 'package:elite_wallet/view_model/wallet_creation_vm.dart';
import 'package:elite_wallet/bitcoin/bitcoin.dart';
import 'package:elite_wallet/haven/haven.dart';
import 'package:elite_wallet/wownero/wownero.dart';

part 'wallet_new_vm.g.dart';

class WalletNewVM = WalletNewVMBase with _$WalletNewVM;

abstract class WalletNewVMBase extends WalletCreationVM with Store {
  WalletNewVMBase(AppStore appStore, WalletCreationService walletCreationService,
      Box<WalletInfo> walletInfoSource,
      {required WalletType type})
      : selectedMnemonicLanguage = '',
        super(appStore, walletInfoSource, walletCreationService, type: type, isRecovery: false);

  @observable
  String selectedMnemonicLanguage;

  bool get hasLanguageSelector => type == WalletType.monero || type == WalletType.haven;

  @override
  WalletCredentials getCredentials(dynamic options) {
    switch (type) {
      case WalletType.monero:
        return monero!.createMoneroNewWalletCredentials(
            name: name, language: options as String);
      case WalletType.bitcoin:
        return bitcoin!.createBitcoinNewWalletCredentials(name: name);
      case WalletType.litecoin:
        return bitcoin!.createBitcoinNewWalletCredentials(name: name);
      case WalletType.haven:
        return haven!.createHavenNewWalletCredentials(
            name: name, language: options as String);
      case WalletType.wownero:
        return wownero!.createWowneroNewWalletCredentials(
            name: name, language: 'English');
      default:
        throw Exception('Unexpected type: ${type.toString()}');;
    }
  }

  @override
  Future<WalletBase> process(WalletCredentials credentials) async {
    walletCreationService.changeWalletType(type: type);
    return walletCreationService.create(credentials);
  }
}
