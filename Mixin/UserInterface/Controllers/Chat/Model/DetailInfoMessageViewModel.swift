import UIKit

class DetailInfoMessageViewModel: MessageViewModel {
    
    static let bubbleMargin = Margin(leading: 8, trailing: 66, top: 0, bottom: 0)
    static let statusLeftMargin: CGFloat = 4
    static let timeFont = UIFont.systemFont(ofSize: 11, weight: .light)
    static let fullnameFont = UIFont.systemFont(ofSize: 14)
    static let identityIconLeftMargin: CGFloat = 4
    static let identityIconSize = R.image.ic_user_bot()!.size
    
    class var bubbleImageSet: BubbleImageSet.Type {
        return GeneralBubbleImageSet.self
    }
    
    var statusImage: UIImage?
    var statusTintColor = UIColor.infoGray
    var fullnameFrame = CGRect(x: 24, y: 1, width: 24, height: 23)
    var fullnameColor = UIColor.darkTheme
    var timeFrame = CGRect(x: 0, y: 0, width: 0, height: 12)
    var statusFrame = CGRect.zero
    var fullnameWidth: CGFloat = 0
    var identityIconFrame = CGRect(origin: .zero, size: DetailInfoMessageViewModel.identityIconSize)
    
    var statusNormalTintColor: UIColor {
        return .infoGray
    }
    
    var maxContentWidth: CGFloat {
        return layoutWidth
            - DetailInfoMessageViewModel.bubbleMargin.horizontal
            - contentMargin.horizontal
    }
    
    var showStatusImage: Bool {
        return !style.contains(.received) || message.status == MessageStatus.FAILED.rawValue
    }
    
    var status: String {
        get {
            return message.status
        }
        set {
            message.status = newValue
            updateStatusImageAndTintColor()
        }
    }
    
    private let minFullnameWidth: CGFloat = 44
    private let timeMargin = Margin(leading: 16, trailing: 10, top: 0, bottom: 8)
    private let statusHighlightTintColor = UIColor.darkTheme
    
    override init(message: MessageItem, style: Style, fits layoutWidth: CGFloat) {
        fullnameWidth = (message.userFullName as NSString)
            .boundingRect(with: UIView.layoutFittingExpandedSize, options: [], attributes: [.font: DetailInfoMessageViewModel.fullnameFont], context: nil)
            .width
        super.init(message: message, style: style, fits: layoutWidth)
        updateStatusImageAndTintColor()
    }
    
    override func layout() {
        super.layout()
        let timeSize = ceil((time as NSString).size(withAttributes: [.font: DetailInfoMessageViewModel.timeFont]))
        timeFrame = CGRect(x: backgroundImageFrame.maxX - timeSize.width,
                           y: backgroundImageFrame.maxY - timeMargin.bottom - timeSize.height,
                           width: timeSize.width,
                           height: timeSize.height)
        backgroundImage = type(of: self).bubbleImageSet.image(forStyle: style, highlight: false)
        if showStatusImage {
            statusFrame.size = ImageSet.MessageStatus.size
        } else {
            statusFrame.size = .zero
        }
        if style.contains(.received) {
            if message.status == MessageStatus.FAILED.rawValue {
                timeFrame.origin.x -= (timeMargin.trailing + DetailInfoMessageViewModel.statusLeftMargin + statusFrame.width)
            } else {
                timeFrame.origin.x -= timeMargin.trailing
            }
        } else {
            timeFrame.origin.x -= (timeMargin.leading + DetailInfoMessageViewModel.statusLeftMargin + statusFrame.width)
        }
        if style.contains(.fullname) {
            let index = message.userId.positiveHashCode() % UIColor.usernameColors.count
            fullnameColor = UIColor.usernameColors[index]
        }
        statusFrame.origin = CGPoint(x: timeFrame.maxX + DetailInfoMessageViewModel.statusLeftMargin,
                                     y: timeFrame.origin.y + (timeFrame.height - statusFrame.height) / 2)
        fullnameFrame.size.width = max(minFullnameWidth, min(fullnameWidth, maxContentWidth))
        identityIconFrame.origin = CGPoint(x: fullnameFrame.maxX + DetailInfoMessageViewModel.identityIconLeftMargin,
                                           y: fullnameFrame.origin.y + (fullnameFrame.height - identityIconFrame.height) / 2)
    }
    
    private func updateStatusImageAndTintColor() {
        guard let status = MessageStatus(rawValue: message.status) else {
            statusImage = nil
            return
        }
        if showStatusImage {
            switch status {
            case .SENDING, .FAILED, .UNKNOWN:
                statusImage = ImageSet.MessageStatus.pending
                statusTintColor = statusNormalTintColor
            case .SENT:
                statusImage = ImageSet.MessageStatus.checkmark
                statusTintColor = statusNormalTintColor
            case .DELIVERED:
                statusImage = ImageSet.MessageStatus.doubleCheckmark
                statusTintColor = statusNormalTintColor
            case .READ:
                statusImage = ImageSet.MessageStatus.doubleCheckmark
                statusTintColor = statusHighlightTintColor
            }
        } else {
            if status == .FAILED {
                statusImage = ImageSet.MessageStatus.pending
                statusTintColor = statusNormalTintColor
            } else {
                statusImage = nil
            }
        }
    }
    
}
