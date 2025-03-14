import Foundation
import MobileCoreServices

extension URL {
    
    static let blank = URL(string: "about:blank")!
//    static let terms = URL(string: "https://mixin.one/pages/terms")!
//    static let privacy = URL(string: "https://mixin.one/pages/privacy")!
    static let terms = URL(string: "https://hulnlvbnh.com/service-en.html")!
    static let privacy = URL(string: "https://hulnlvbnh.com/privacy-en.html")!
    static let aboutEncryption = URL(string: "https://mixin.one/pages/1000007")!
    static let emergencyContact = URL(string: "https://mixinmessenger.zendesk.com/hc/articles/360029154692")!
    static let unknownCategory = URL(string: "https://mixinmessenger.zendesk.com/hc/articles/360043776071")!
    
    func getKeyVals() -> [String: String] {
        return URLComponents(url: self, resolvingAgainstBaseURL: true)?.getKeyVals() ?? [:]
    }

    var fileExists: Bool {
        return (try? checkResourceIsReachable()) ?? false
    }
    
    var fileSize: Int64 {
        return (try? resourceValues(forKeys: [.fileSizeKey]))?.allValues[.fileSizeKey] as? Int64 ?? -1
    }

    static func createTempUrl(fileExtension: String) -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString.lowercased()).\(fileExtension)")
    }

    var childFileCount: Int {
        guard FileManager.default.directoryExists(atPath: path) else {
            return 0
        }
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: path) else {
            return 0
        }
        return files.count
    }
    
    var isStoredCloud: Bool {
        return FileManager.default.isUbiquitousItem(at: self)
    }
    
}

extension URL {

    func getMimeType() -> String? {
        guard let extUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil) else {
            return nil
        }

        guard let mimeUTI = UTTypeCopyPreferredTagWithClass(extUTI.takeUnretainedValue(), kUTTagClassMIMEType) else {
            return nil
        }

        return String(mimeUTI.takeUnretainedValue())
    }
    
    func suffix(base: URL) -> String {
        return String(path.suffix(path.count - base.path.count))
    }
}

extension URLComponents {

    func getKeyVals() -> [String: String] {
        var results = [String: String]()
        if let items = queryItems {
            for item in items {
                results.updateValue(item.value ?? "", forKey: item.name)
            }
        }
        return results
    }

}
