import Foundation

var isAppExtension: Bool {
    Bundle.main.bundleURL.pathExtension == "appex"
}
