class PreferencesKey {
  static const currentWalletType = 'current_wallet_type';
  static const currentWalletName = 'current_wallet_name';
  static const currentNodeIdKey = 'current_node_id';
  static const currentBitcoinElectrumSererIdKey = 'current_node_id_btc';
  static const currentLitecoinElectrumSererIdKey = 'current_node_id_ltc';
  static const currentHavenNodeIdKey = 'current_node_id_xhv';
  static const currentWowneroNodeIdKey = 'current_node_id_wow';
  static const currentFiatCurrencyKey = 'current_fiat_currency';
  static const currentTransactionPriorityKeyLegacy = 'current_fee_priority';
  static const currentBalanceDisplayModeKey = 'current_balance_display_mode';
  static const shouldSaveRecipientAddressKey = 'save_recipient_address';
  static const isAppSecureKey = 'is_app_secure';
  static const disableBuyKey = 'disable_buy';
  static const disableSellKey = 'disable_sell';
  static const currentFiatApiModeKey = 'current_fiat_api_mode';
  static const proxyEnabledKey = 'proxy_enabled';
  static const proxyIPAddressKey = 'proxy_ip_address';
  static const proxyPortKey = 'proxy_port';
  static const proxyAuthenticationEnabledKey = 'proxy_authentication';
  static const proxyUsernameKey = 'proxy_username';
  static const proxyPasswordKey = 'proxy_password';
  static const portScanEnabledKey = 'proxy_port_scan_enabled';
  static const allowBiometricalAuthenticationKey =
      'allow_biometrical_authentication';
  static const useTOTP2FA = 'use_totp_2fa';
  static const failedTotpTokenTrials = 'failed_token_trials';
  static const totpSecretKey = 'totp_qr_secret_key';
  static const disableExchangeKey = 'disable_exchange';
  static const exchangeStatusKey = 'exchange_status';
  static const currentTheme = 'current_theme';
  static const isDarkThemeLegacy = 'dark_theme';
  static const displayActionListModeKey = 'display_list_mode';
  static const currentPinLength = 'current_pin_length';
  static const currentLanguageCode = 'language_code';
  static const cryptoPriceProvider = 'crypto_price_provider';
  static const currentDefaultSettingsMigrationVersion =
      'current_default_settings_migration_version';
  static const moneroTransactionPriority = 'current_fee_priority_monero';
  static const bitcoinTransactionPriority = 'current_fee_priority_bitcoin';
  static const havenTransactionPriority = 'current_fee_priority_haven';
  static const litecoinTransactionPriority = 'current_fee_priority_litecoin';
  static const wowneroTransactionPriority = 'current_fee_priority_wownero';
  static const shouldShowReceiveWarning = 'should_show_receive_warning';
  static const shouldShowYatPopup = 'should_show_yat_popup';
  static const moneroWalletPasswordUpdateV1Base = 'monero_wallet_update_v1';
  static const pinTimeOutDuration = 'pin_timeout_duration';
  static const lastAuthTimeMilliseconds = 'last_auth_time_milliseconds';
  static const lastPopupDate = 'last_popup_date';
  static const lastAppReviewDate = 'last_app_review_date';



  static String moneroWalletUpdateV1Key(String name)
    => '${PreferencesKey.moneroWalletPasswordUpdateV1Base}_${name}';

  static const exchangeProvidersSelection = 'exchange-providers-selection';
  static const clearnetDonationLink = 'clearnet_donation_link'; 
  static const onionDonationLink = 'onion_donation_link';
  static const lastSeenAppVersion = 'last_seen_app_version';
  static const shouldShowMarketPlaceInDashboard = 'should_show_marketplace_in_dashboard';
  static const isNewInstall = 'is_new_install';
  static const selectNodeAutomatically = 'select_node_automatically';
  static const userExperience = 'user_experience';
}
