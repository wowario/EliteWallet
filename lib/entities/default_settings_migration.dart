import 'dart:io' show File, Platform;
import 'package:elite_wallet/bitcoin/bitcoin.dart';
import 'package:elite_wallet/entities/exchange_api_mode.dart';
import 'package:ew_core/pathForWallet.dart';
import 'package:elite_wallet/entities/secret_store_key.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elite_wallet/entities/preferences_key.dart';
import 'package:ew_core/wallet_type.dart';
import 'package:ew_core/node.dart';
import 'package:elite_wallet/entities/balance_display_mode.dart';
import 'package:elite_wallet/entities/fiat_currency.dart';
import 'package:elite_wallet/entities/node_list.dart';
import 'package:elite_wallet/monero/monero.dart';
import 'package:elite_wallet/entities/contact.dart';
import 'package:elite_wallet/entities/fs_migration.dart';
import 'package:ew_core/wallet_info.dart';
import 'package:elite_wallet/exchange/trade.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:collection/collection.dart';

const newEliteWalletMoneroUri = 'node.community.rino.io:18081';
const eliteWalletBitcoinElectrumUri = 'fortress.qtornado.com:443';
const eliteWalletLitecoinElectrumUri = 'electrum.ltc.xurious.com:50002';
const havenDefaultNodeUri = 'nodes.havenprotocol.org:443';
const wowneroDefaultNodeUri = 'eu-west-2.wow.xmr.pm:34568';

Future defaultSettingsMigration(
    {required int version,
    required SharedPreferences sharedPreferences,
    required FlutterSecureStorage secureStorage,
    required Box<Node> nodes,
    required Box<WalletInfo> walletInfoSource,
    required Box<Trade> tradeSource,
    required Box<Contact> contactSource}) async {
  if (Platform.isIOS) {
    await ios_migrate_v1(walletInfoSource, tradeSource, contactSource);
  }

  // check current nodes for nullability regardless of the version
  await checkCurrentNodes(nodes, sharedPreferences);

  final isNewInstall = sharedPreferences
      .getInt(PreferencesKey.currentDefaultSettingsMigrationVersion) == null;

  await sharedPreferences.setBool(
      PreferencesKey.isNewInstall, isNewInstall);

  final currentVersion = sharedPreferences
          .getInt(PreferencesKey.currentDefaultSettingsMigrationVersion) ??
      0;
  if (currentVersion >= version) {
    return;
  }

  final migrationVersionsLength = version - currentVersion;
  final migrationVersions = List<int>.generate(
      migrationVersionsLength, (i) => currentVersion + (i + 1));

  await Future.forEach(migrationVersions, (int version) async {
    try {
      switch (version) {
        case 1:
          await sharedPreferences.setString(
              PreferencesKey.currentFiatCurrencyKey,
              FiatCurrency.usd.toString());
          await sharedPreferences.setInt(
              PreferencesKey.currentTransactionPriorityKeyLegacy,
              monero!.getDefaultTransactionPriority().raw);
          await sharedPreferences.setInt(
              PreferencesKey.currentBalanceDisplayModeKey,
              BalanceDisplayMode.availableBalance.raw);
          await sharedPreferences.setBool('save_recipient_address', true);
          await resetToDefault(nodes);
          await changeMoneroCurrentNodeToDefault(
              sharedPreferences: sharedPreferences, nodes: nodes);
          await changeBitcoinCurrentElectrumServerToDefault(
              sharedPreferences: sharedPreferences, nodes: nodes);
          await changeLitecoinCurrentElectrumServerToDefault(
              sharedPreferences: sharedPreferences, nodes: nodes);
          await changeHavenCurrentNodeToDefault(
              sharedPreferences: sharedPreferences, nodes: nodes);

          break;
        case 2:
          await replaceNodesMigration(nodes: nodes);
          await replaceDefaultNode(
              sharedPreferences: sharedPreferences, nodes: nodes);

          break;
        case 3:
          await updateNodeTypes(nodes: nodes);
          await addBitcoinElectrumServerList(nodes: nodes);

          break;
        case 4:
          await changeBitcoinCurrentElectrumServerToDefault(
              sharedPreferences: sharedPreferences, nodes: nodes);
          break;

        case 5:
          await addAddressesForMoneroWallets(walletInfoSource);
          break;

        case 6:
          await updateDisplayModes(sharedPreferences);
          break;

        case 9:
          await generateBackupPassword(secureStorage);
          break;

        case 10:
          await changeTransactionPriorityAndFeeRateKeys(sharedPreferences);
          break;

        case 11:
          await changeDefaultMoneroNode(nodes, sharedPreferences);
          break;

        case 12:
          await checkCurrentNodes(nodes, sharedPreferences);
          break;

        case 13:
          await resetBitcoinElectrumServer(nodes, sharedPreferences);
          break;

        case 15:
          await addLitecoinElectrumServerList(nodes: nodes);
          await changeLitecoinCurrentElectrumServerToDefault(
              sharedPreferences: sharedPreferences, nodes: nodes);
          await checkCurrentNodes(nodes, sharedPreferences);
          break;

        case 16:
          await addHavenNodeList(nodes: nodes);
          await changeHavenCurrentNodeToDefault(
              sharedPreferences: sharedPreferences, nodes: nodes);
          await checkCurrentNodes(nodes, sharedPreferences);
          break;

        case 17:
          await changeDefaultHavenNode(nodes);
          break;

        case 18:
          await addWowneroNodeList(nodes: nodes);
          await changeWowneroCurrentNodeToDefault(
              sharedPreferences: sharedPreferences, nodes: nodes);
          await checkCurrentNodes(nodes, sharedPreferences);
          break;

        case 19:
          await addOnionNode(nodes);
          break;

        case 20:
          await validateBitcoinSavedTransactionPriority(sharedPreferences);
          break;

        case 21:
          await migrateExchangeStatus(sharedPreferences);
          break;

        case 22:
          await addBitcoinElectrumServerList(nodes: nodes);
          await removeUnreliableBitcoinElectrumNodes(nodes: nodes);
          break;

        default:
          break;
      }

      await sharedPreferences.setInt(
          PreferencesKey.currentDefaultSettingsMigrationVersion, version);
    } catch (e) {
      print('Migration error: ${e.toString()}');
    }
  });

  await sharedPreferences.setInt(
      PreferencesKey.currentDefaultSettingsMigrationVersion, version);
}

Future<void> validateBitcoinSavedTransactionPriority(SharedPreferences sharedPreferences) async {
  if (bitcoin == null) {
    return;
  }
  final int? savedBitcoinPriority =
      sharedPreferences.getInt(PreferencesKey.bitcoinTransactionPriority);
  if (!bitcoin!.getTransactionPriorities().any((element) => element.raw == savedBitcoinPriority)) {
    await sharedPreferences.setInt(
        PreferencesKey.bitcoinTransactionPriority, bitcoin!.getMediumTransactionPriority().serialize());
  }
}

Future<void> addOnionNode(Box<Node> nodes) async {
  final onionNodeUri = "cakexmrl7bonq7ovjka5kuwuyd3f7qnkz6z6s6dmsy3uckwra7bvggyd.onion:18081";

  // check if the user has this node before (added it manually)
  if (nodes.values.firstWhereOrNull((element) => element.uriRaw == onionNodeUri) == null) {
    await nodes.add(Node(uri: onionNodeUri, type: WalletType.monero));
  }
}

Future<void> replaceNodesMigration({required Box<Node> nodes}) async {
  final replaceNodes = <String, Node>{
    'eu-node.cakewallet.io:18081':
        Node(uri: 'xmr-node-eu.cakewallet.com:18081', type: WalletType.monero),
    'node.cakewallet.io:18081': Node(
        uri: 'xmr-node-usa-east.cakewallet.com:18081', type: WalletType.monero),
    'node.xmr.ru:13666':
        Node(uri: 'node.monero.net:18081', type: WalletType.monero)
  };

  nodes.values.forEach((Node node) async {
    final nodeToReplace = replaceNodes[node.uri];

    if (nodeToReplace != null) {
      node.uriRaw = nodeToReplace.uriRaw;
      node.login = nodeToReplace.login;
      node.password = nodeToReplace.password;
      await node.save();
    }
  });
}

Future<void> changeMoneroCurrentNodeToDefault(
    {required SharedPreferences sharedPreferences,
    required Box<Node> nodes}) async {
  final node = getMoneroDefaultNode(nodes: nodes);
  final nodeId = node?.key as int ?? 0; // 0 - England

  await sharedPreferences.setInt(PreferencesKey.currentNodeIdKey, nodeId);
}

Node? getBitcoinDefaultElectrumServer({required Box<Node> nodes}) {
    return nodes.values.firstWhereOrNull(
          (Node node) => node.uriRaw == eliteWalletBitcoinElectrumUri)
          ?? nodes.values.firstWhereOrNull((node) => node.type == WalletType.bitcoin);
}

Node? getLitecoinDefaultElectrumServer({required Box<Node> nodes}) {
    return nodes.values.firstWhereOrNull(
          (Node node) => node.uriRaw == eliteWalletLitecoinElectrumUri)
          ?? nodes.values.firstWhereOrNull((node) => node.type == WalletType.litecoin);
}

Node? getHavenDefaultNode({required Box<Node> nodes}) {
    return nodes.values.firstWhereOrNull(
          (Node node) => node.uriRaw == havenDefaultNodeUri)
          ?? nodes.values.firstWhereOrNull((node) => node.type == WalletType.haven);
}

Node? getWowneroDefaultNode({required Box<Node> nodes}) {
  return nodes.values.firstWhereOrNull(
          (Node node) => node.uriRaw == wowneroDefaultNodeUri)
          ?? nodes.values.firstWhereOrNull((node) => node.type == WalletType.wownero);
}

Node getMoneroDefaultNode({required Box<Node> nodes}) {
  final timeZone = DateTime.now().timeZoneOffset.inHours;
  var nodeUri = '';

  if (timeZone >= 1) {
    // Eurasia
    nodeUri = 'xmr-node-eu.cakewallet.com:18081';
  } else if (timeZone <= -4) {
    // America
    nodeUri = 'xmr-node-usa-east.cakewallet.com:18081';
  }

  try {
    return nodes.values
          .firstWhere((Node node) => node.uriRaw == nodeUri);
  } catch(_) {
    return nodes.values.first;
  }
}

Future<void> changeBitcoinCurrentElectrumServerToDefault(
    {required SharedPreferences sharedPreferences,
    required Box<Node> nodes}) async {
  final server = getBitcoinDefaultElectrumServer(nodes: nodes);
  final serverId = server?.key as int ?? 0;

  await sharedPreferences.setInt(PreferencesKey.currentBitcoinElectrumSererIdKey, serverId);
}

Future<void> changeLitecoinCurrentElectrumServerToDefault(
    {required SharedPreferences sharedPreferences,
    required Box<Node> nodes}) async {
  final server = getLitecoinDefaultElectrumServer(nodes: nodes);
  final serverId = server?.key as int ?? 0;

  await sharedPreferences.setInt(PreferencesKey.currentLitecoinElectrumSererIdKey, serverId);
}

Future<void> changeHavenCurrentNodeToDefault(
    {required SharedPreferences sharedPreferences,
    required Box<Node> nodes}) async {
  final node = getHavenDefaultNode(nodes: nodes);
  final nodeId = node?.key as int ?? 0;

  await sharedPreferences.setInt(PreferencesKey.currentHavenNodeIdKey, nodeId);
}

Future<void> changeWowneroCurrentNodeToDefault(
    {required SharedPreferences sharedPreferences,
    required Box<Node> nodes}) async {
  final node = getWowneroDefaultNode(nodes: nodes);
  final nodeId = node?.key as int ?? 0;

  await sharedPreferences.setInt(PreferencesKey.currentWowneroNodeIdKey, nodeId);
}

Future<void> replaceDefaultNode(
    {required SharedPreferences sharedPreferences,
    required Box<Node> nodes}) async {
  const nodesForReplace = <String>[
    'xmr-node-uk.cakewallet.com:18081',
    'eu-node.cakewallet.io:18081',
    'node.cakewallet.io:18081'
  ];
  final currentNodeId = sharedPreferences.getInt(PreferencesKey.currentNodeIdKey);
  final currentNode =
      nodes.values.firstWhereOrNull((Node node) => node.key == currentNodeId);
  final needToReplace =
      currentNode == null ? true : nodesForReplace.contains(currentNode.uriRaw);

  if (!needToReplace) {
    return;
  }

  await changeMoneroCurrentNodeToDefault(
      sharedPreferences: sharedPreferences, nodes: nodes);
}

Future<void> updateNodeTypes({required Box<Node> nodes}) async {
  nodes.values.forEach((node) async {
    if (node.type == null) {
      node.type = WalletType.monero;
      await node.save();
    }
  });
}

Future<void> addBitcoinElectrumServerList({required Box<Node> nodes}) async {
  final serverList = await loadBitcoinElectrumServerList();
  for (var node in serverList) {
    if (nodes.values.firstWhereOrNull((element) => element.uriRaw == node.uriRaw) == null) {
      await nodes.add(node);
    }
  }
}

Future<void> addLitecoinElectrumServerList({required Box<Node> nodes}) async {
  final serverList = await loadLitecoinElectrumServerList();
  for (var node in serverList) {
    if (nodes.values.firstWhereOrNull((element) => element.uriRaw == node.uriRaw) == null) {
      await nodes.add(node);
    }
  }
}

Future<void> addHavenNodeList({required Box<Node> nodes}) async {
  final nodeList = await loadDefaultHavenNodes();
  for (var node in nodeList) {
    if (nodes.values.firstWhereOrNull((element) => element.uriRaw == node.uriRaw) == null) {
      await nodes.add(node);
    }
  }
}

Future<void> addWowneroNodeList({required Box<Node> nodes}) async {
  final nodeList = await loadDefaultWowneroNodes();
  for (var node in nodeList) {
    if (nodes.values.firstWhereOrNull((element) => element.uriRaw == node.uriRaw) == null) {
      await nodes.add(node);
    }
  }
}

Future<void> addAddressesForMoneroWallets(
    Box<WalletInfo> walletInfoSource) async {
  final moneroWalletsInfo =
      walletInfoSource.values.where((info) => info.type == WalletType.monero);
  moneroWalletsInfo.forEach((info) async {
    try {
      final walletPath =
          await pathForWallet(name: info.name, type: WalletType.monero);
      final addressFilePath = '$walletPath.address.txt';
      final addressFile = File(addressFilePath);

      if (!addressFile.existsSync()) {
        return;
      }

      final addressText = await addressFile.readAsString();
      info.address = addressText;
      await info.save();
    } catch (e) {
      print(e.toString());
    }
  });
}

Future<void> updateDisplayModes(SharedPreferences sharedPreferences) async {
  final currentBalanceDisplayMode =
      sharedPreferences.getInt(PreferencesKey.currentBalanceDisplayModeKey) ?? -1;
  final balanceDisplayMode = currentBalanceDisplayMode < 2 ? 3 : 2;
  await sharedPreferences.setInt(
      PreferencesKey.currentBalanceDisplayModeKey, balanceDisplayMode);
}

Future<void> generateBackupPassword(FlutterSecureStorage secureStorage) async {
  final key = generateStoreKeyFor(key: SecretStoreKey.backupPassword);

  if ((await secureStorage.read(key: key))?.isNotEmpty ?? false) {
    return;
  }

  final password = encrypt.Key.fromSecureRandom(32).base16;
  await secureStorage.write(key: key, value: password);
}

Future<void> changeTransactionPriorityAndFeeRateKeys(
    SharedPreferences sharedPreferences) async {
  final legacyTransactionPriority = sharedPreferences
      .getInt(PreferencesKey.currentTransactionPriorityKeyLegacy)!;
  await sharedPreferences.setInt(
      PreferencesKey.moneroTransactionPriority, legacyTransactionPriority);
  await sharedPreferences.setInt(PreferencesKey.bitcoinTransactionPriority,
      bitcoin!.getMediumTransactionPriority().serialize());
}

Future<void> changeDefaultMoneroNode(
    Box<Node> nodeSource, SharedPreferences sharedPreferences) async {
  const eliteWalletMoneroNodeUriPattern = '.cakewallet.com';
  final currentMoneroNodeId =
      sharedPreferences.getInt(PreferencesKey.currentNodeIdKey);
  final currentMoneroNode =
      nodeSource.values.firstWhere((node) => node.key == currentMoneroNodeId);
  final needToReplaceCurrentMoneroNode =
      currentMoneroNode.uri.toString().contains(eliteWalletMoneroNodeUriPattern);

  nodeSource.values.forEach((node) async {
    if (node.type == WalletType.monero &&
        node.uri.toString().contains(eliteWalletMoneroNodeUriPattern)) {
      await node.delete();
    }
  });

  final newEliteWalletNode =
      Node(uri: newEliteWalletMoneroUri, type: WalletType.monero);

  await nodeSource.add(newEliteWalletNode);

  if (needToReplaceCurrentMoneroNode) {
    await sharedPreferences.setInt(
        PreferencesKey.currentNodeIdKey, newEliteWalletNode.key as int);
  }
}

Future<void> checkCurrentNodes(
    Box<Node> nodeSource, SharedPreferences sharedPreferences) async {
  final currentMoneroNodeId =
      sharedPreferences.getInt(PreferencesKey.currentNodeIdKey);
  final currentBitcoinElectrumSeverId =
      sharedPreferences.getInt(PreferencesKey.currentBitcoinElectrumSererIdKey);
  final currentLitecoinElectrumSeverId = sharedPreferences
      .getInt(PreferencesKey.currentLitecoinElectrumSererIdKey);
  final currentHavenNodeId = sharedPreferences
      .getInt(PreferencesKey.currentHavenNodeIdKey);
  final currentWowneroNodeId = sharedPreferences
      .getInt(PreferencesKey.currentWowneroNodeIdKey);
  final currentMoneroNode = nodeSource.values.firstWhereOrNull(
      (node) => node.key == currentMoneroNodeId);
  final currentBitcoinElectrumServer = nodeSource.values.firstWhereOrNull(
      (node) => node.key == currentBitcoinElectrumSeverId);
  final currentLitecoinElectrumServer = nodeSource.values.firstWhereOrNull(
      (node) => node.key == currentLitecoinElectrumSeverId);
  final currentHavenNodeServer = nodeSource.values.firstWhereOrNull(
      (node) => node.key == currentHavenNodeId);
  final currentWowneroNodeServer = nodeSource.values.firstWhereOrNull(
      (node) => node.key == currentWowneroNodeId);

  if (currentMoneroNode == null) {
    final newEliteWalletNode =
        Node(uri: newEliteWalletMoneroUri, type: WalletType.monero);
    await nodeSource.add(newEliteWalletNode);
    await sharedPreferences.setInt(
        PreferencesKey.currentNodeIdKey, newEliteWalletNode.key as int);
  }

  if (currentBitcoinElectrumServer == null) {
    final eliteWalletElectrum =
        Node(uri: eliteWalletBitcoinElectrumUri, type: WalletType.bitcoin);
    await nodeSource.add(eliteWalletElectrum);
    await sharedPreferences.setInt(
        PreferencesKey.currentBitcoinElectrumSererIdKey,
        eliteWalletElectrum.key as int);
  }

  if (currentLitecoinElectrumServer == null) {
    final eliteWalletElectrum =
        Node(uri: eliteWalletLitecoinElectrumUri, type: WalletType.litecoin);
    await nodeSource.add(eliteWalletElectrum);
    await sharedPreferences.setInt(
        PreferencesKey.currentLitecoinElectrumSererIdKey,
        eliteWalletElectrum.key as int);
  }

  if (currentHavenNodeServer == null) {
    final node = Node(uri: havenDefaultNodeUri, type: WalletType.haven);
    await nodeSource.add(node);
    await sharedPreferences.setInt(
        PreferencesKey.currentHavenNodeIdKey, node.key as int);
  }

  if (currentWowneroNodeServer == null) {
    final node = Node(uri: wowneroDefaultNodeUri, type: WalletType.wownero);
    await nodeSource.add(node);
    await sharedPreferences.setInt(
        PreferencesKey.currentWowneroNodeIdKey, node.key as int);
  }
}

Future<void> resetBitcoinElectrumServer(
    Box<Node> nodeSource, SharedPreferences sharedPreferences) async {
  final currentElectrumSeverId =
      sharedPreferences.getInt(PreferencesKey.currentBitcoinElectrumSererIdKey);
  final oldElectrumServer = nodeSource.values.firstWhereOrNull(
      (node) => node.uri.toString().contains('electrumx.cakewallet.com'));
  var eliteWalletNode = nodeSource.values.firstWhereOrNull(
      (node) => node.uriRaw.toString() == eliteWalletBitcoinElectrumUri);

  if (eliteWalletNode == null) {
    eliteWalletNode =
        Node(uri: eliteWalletBitcoinElectrumUri, type: WalletType.bitcoin);
    await nodeSource.add(eliteWalletNode);
  }

  if (currentElectrumSeverId == oldElectrumServer?.key) {
    await sharedPreferences.setInt(
        PreferencesKey.currentBitcoinElectrumSererIdKey,
        eliteWalletNode.key as int);
  }

  await oldElectrumServer?.delete();
}

Future<void> changeDefaultHavenNode(
    Box<Node> nodeSource) async {
  const previousHavenDefaultNodeUri = 'vault.havenprotocol.org:443';
  final havenNodes = nodeSource.values.where(
      (node) => node.uriRaw == previousHavenDefaultNodeUri);
  havenNodes.forEach((node) async {
    node.uriRaw = havenDefaultNodeUri;
    await node.save();
  });
}

Future<void> migrateExchangeStatus(SharedPreferences sharedPreferences) async {
  final isExchangeDisabled = sharedPreferences.getBool(PreferencesKey.disableExchangeKey);
  if (isExchangeDisabled == null) {
    return;
  }

  await sharedPreferences.setInt(PreferencesKey.exchangeStatusKey, isExchangeDisabled 
      ? ExchangeApiMode.disabled.raw : ExchangeApiMode.enabled.raw);
      
  await sharedPreferences.remove(PreferencesKey.disableExchangeKey);
}

Future<void> removeUnreliableBitcoinElectrumNodes({required Box<Node> nodes}) async {
  nodes.values.forEach((node) async {
    if (node.type == WalletType.bitcoin &&
        (node.uri.toString().contains('electrum.bitcoinlizard.net:50002') ||
         node.uri.toString().contains('electrumx-btc.cryptonermal.net:50002') ||
         node.uri.toString().contains('ulrichard.ch:50002'))) {
      await node.delete();
    }
  });
}
