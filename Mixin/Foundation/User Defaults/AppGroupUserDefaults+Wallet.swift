import Foundation

extension AppGroupUserDefaults {
    
    public enum Wallet {
        
        enum Key: String, CaseIterable {
            case lastPinVerifiedDate = "last_pin_verified_date"
            case periodicPinVerificationInterval = "periodic_pin_verification_interval"
            
            case usesBiometricPayment = "uses_biometric_payment"
            case biometricPaymentExpirationInterval = "biometric_payment_expiration_interval"
            
            case defaultTransferAssetId = "default_transfer_asset_id"
            case hiddenAssetIds = "hidden_asset_ids"
            case allTransactionsOffset = "all_transactions_offset"
            case assetTransactionsOffset = "asset_transactions_offset"
            case currencyCode = "currency_code"
        }
        
        @NullableDefault(namespace: .wallet, key: Key.lastPinVerifiedDate, defaultValue: nil)
        public static var lastPinVerifiedDate: Date?
        
        // FIXME: Clamp
        @Default(namespace: .wallet, key: Key.periodicPinVerificationInterval, defaultValue: 0)
        public static var periodicPinVerificationInterval: TimeInterval
        
        @Default(namespace: .wallet, key: Key.usesBiometricPayment, defaultValue: false)
        public static var usesBiometricPayment: Bool
        
        // FIXME: Clamp
        @Default(namespace: .wallet, key: Key.biometricPaymentExpirationInterval, defaultValue: 0)
        public static var biometricPaymentExpirationInterval: TimeInterval
        
        @NullableDefault(namespace: .wallet, key: Key.defaultTransferAssetId, defaultValue: nil)
        public static var defaultTransferAssetId: String?
        
        @Default(namespace: .wallet, key: Key.hiddenAssetIds, defaultValue: [:])
        public static var hiddenAssetIds: [String: Bool]
        
        @NullableDefault(namespace: .wallet, key: Key.allTransactionsOffset, defaultValue: nil)
        public static var allTransactionsOffset: String?
        
        @Default(namespace: .wallet, key: Key.assetTransactionsOffset, defaultValue: nil)
        public static var assetTransactionsOffset: [String: String]
        
        @NullableDefault(namespace: .wallet, key: Key.currencyCode, defaultValue: nil)
        public static var currencyCode: String?
        
        internal static func migrate() {
            lastPinVerifiedDate = Date(timeIntervalSince1970: WalletUserDefault.shared.lastInputPinTime)
            periodicPinVerificationInterval = WalletUserDefault.shared.checkPinInterval
            
            usesBiometricPayment = WalletUserDefault.shared.isBiometricPay
            biometricPaymentExpirationInterval = WalletUserDefault.shared.pinInterval
            
            defaultTransferAssetId = WalletUserDefault.shared.defalutTransferAssetId
            hiddenAssetIds = WalletUserDefault.shared.hiddenAssets as? [String: Bool] ?? [:]
            allTransactionsOffset = WalletUserDefault.shared.allTransactionOffset
            assetTransactionsOffset = WalletUserDefault.shared.assetTransactionOffset
            currencyCode = WalletUserDefault.shared.currencyCode
        }
        
    }
    
}
