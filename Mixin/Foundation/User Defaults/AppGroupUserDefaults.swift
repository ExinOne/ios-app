import Foundation

public enum AppGroupUserDefaults {
    
    internal static let defaults = UserDefaults(suiteName: "group.one.mixin.messenger")!
    
    public enum Namespace {
        case crypto
        case account
        case user
        case database
        case wallet
        
        var stringValue: String {
            switch self {
            case .crypto:
                return "crypto"
            case .account:
                return "account"
            case .user:
                return "user." + AccountAPI.shared.accountIdentityNumber
            case .database:
                return "database." + AccountAPI.shared.accountIdentityNumber
            case .wallet:
                return "wallet." + AccountAPI.shared.accountIdentityNumber
            }
        }
    }
    
    // Property wrapper not working optional Value types
    // Use NullableDefault<Value> if value type is optional
    @propertyWrapper
    public class Default<Value> {
        
        fileprivate let key: String
        fileprivate let defaultValue: Value
        
        public init(namespace: Namespace?, key: String, defaultValue: Value) {
            if let namespace = namespace {
                self.key = namespace.stringValue + "." + key
            } else {
                self.key = key
            }
            self.defaultValue = defaultValue
        }
        
        public convenience init<KeyType: RawRepresentable>(namespace: Namespace?, key: KeyType, defaultValue: Value) where KeyType.RawValue == String {
            self.init(namespace: namespace, key: key.rawValue, defaultValue: defaultValue)
        }
        
        public var wrappedValue: Value {
            get {
                defaults.object(forKey: key) as? Value ?? defaultValue
            }
            set {
                defaults.set(newValue, forKey: key)
            }
        }
        
    }
    
    @propertyWrapper
    public class NullableDefault<Value>: Default<Optional<Value>> {
        
        public override var wrappedValue: Value? {
            get {
                defaults.object(forKey: key) as? Value ?? defaultValue
            }
            set {
                if let value = newValue {
                    defaults.set(value, forKey: key)
                } else {
                    defaults.removeObject(forKey: key)
                }
            }
        }
        
    }
    
    @propertyWrapper
    public class RawRepresentableDefault<Value: RawRepresentable>: Default<Value> {
        
        public override var wrappedValue: Value {
            get {
                if let rawValue = defaults.object(forKey: key) as? Value.RawValue, let value = Value(rawValue: rawValue) {
                    return value
                } else {
                    return defaultValue
                }
            }
            set {
                defaults.set(newValue.rawValue, forKey: key)
            }
        }
        
    }
    
}

extension AppGroupUserDefaults {
    
    public static let version = 1
    
    @Default(namespace: nil, key: "local_version", defaultValue: 0)
    public static var localVersion: Int
    
    // Indicates that user defaults are in Main app's container and needs to migrate to AppGroup's container
    public static var needsMigration: Bool {
        localVersion == 0
    }
    
    public static var canMigrate: Bool {
        !isAppExtension
    }
    
    // Indicates that user defaults are outdated but do present in AppGroup's container
    public static var needsUpgrade: Bool {
        localVersion != 0 && version > localVersion
    }
    
    @Default(namespace: nil, key: "first_launch_date", defaultValue: Date())
    public static var firstLaunchDate: Date
    
}

extension AppGroupUserDefaults {
    
    public static func migrateIfNeeded() {
        guard needsMigration else {
            return
        }
        Crypto.migrate()
        Database.migrate()
        Account.migrate()
        User.migrate()
        Wallet.migrate()
        localVersion = version
    }
    
}
