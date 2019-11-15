import Foundation

public enum AutoDownload: Int {
    case never = 0
    case wifi
    case wifiAndCellular
    
    var description: String {
        switch self {
        case .never:
            return R.string.localizable.setting_auto_download_never()
        case .wifi:
            return R.string.localizable.setting_auto_download_wifi()
        case .wifiAndCellular:
            return R.string.localizable.setting_auto_download_wifi_cellular()
        }
    }
}
