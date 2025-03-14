import UIKit
import MixinServices

class TranscriptMessageViewModel: TextMessageViewModel {
    
    static let maxNumberOfDigestLines = 4
    static let transcriptBackgroundMargin = Margin(leading: -6, trailing: -5, top: 4, bottom: 2)
    static let transcriptInterlineSpacing: CGFloat = 4
    
    let contents: [TranscriptMessage.LocalContent]
    let digests: [String]
    
    private let transcriptInset = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
    
    private(set) var transcriptBackgroundFrame: CGRect = .zero
    private(set) var transcriptFrame: CGRect = .zero
    
    private var digestsHeight: CGFloat = 0
    
    override var rawContent: String {
        R.string.localizable.chat_transcript()
    }
    
    override var backgroundWidth: CGFloat {
        layoutWidth - DetailInfoMessageViewModel.bubbleMargin.horizontal
    }
    
    override init(message: MessageItem) {
        if let data = message.content?.data(using: .utf8), let contents = try? JSONDecoder.default.decode([TranscriptMessage.LocalContent].self, from: data) {
            self.contents = contents
        } else {
            self.contents = []
        }
        self.digests = self.contents
            .prefix(Self.maxNumberOfDigestLines)
            .map(Self.digest(of:))
        super.init(message: message)
    }
    
    override func linkRanges(from string: String) -> [Link.Range] {
        []
    }
    
    override func layout(width: CGFloat, style: MessageViewModel.Style) {
        digestsHeight = Self.transcriptBackgroundMargin.vertical
            + CGFloat(digests.count - 1) * Self.transcriptInterlineSpacing
            + CGFloat(digests.count) * MessageFontSet.transcriptDigest.scaled.lineHeight
            + transcriptInset.vertical
        super.layout(width: width, style: style)
        transcriptBackgroundFrame = CGRect(x: contentLabelFrame.origin.x + Self.transcriptBackgroundMargin.leading,
                                           y: contentLabelFrame.maxY + Self.transcriptBackgroundMargin.top,
                                           width: backgroundWidth - contentAdditionalLeadingMargin - contentMargin.horizontal - Self.transcriptBackgroundMargin.horizontal,
                                           height: digestsHeight - Self.transcriptBackgroundMargin.bottom)
        transcriptFrame = transcriptBackgroundFrame.inset(by: transcriptInset)
    }
    
    override func adjustedContentSize(_ raw: CGSize) -> CGSize {
        return CGSize(width: raw.width, height: raw.height + digestsHeight)
    }
    
}

extension TranscriptMessageViewModel  {
    
    private static func digest(of content: TranscriptMessage.LocalContent) -> String {
        var digest: String
        if let username = content.name {
            digest = username + ": "
        } else {
            digest = ""
        }
        switch MessageCategory(rawValue: content.category) {
        case .SIGNAL_TEXT, .PLAIN_TEXT:
            digest += content.content ?? " "
        case .SIGNAL_IMAGE, .PLAIN_IMAGE:
            digest += R.string.localizable.notification_content_photo()
        case .SIGNAL_VIDEO, .PLAIN_VIDEO:
            digest += R.string.localizable.notification_content_video()
        case .SIGNAL_DATA, .PLAIN_DATA:
            digest += R.string.localizable.notification_content_file()
        case .SIGNAL_STICKER, .PLAIN_STICKER:
            digest += R.string.localizable.notification_content_sticker()
        case .SIGNAL_CONTACT, .PLAIN_CONTACT:
            digest += R.string.localizable.notification_content_contact()
        case .SIGNAL_AUDIO, .PLAIN_AUDIO:
            digest += R.string.localizable.notification_content_audio()
        case .SIGNAL_LIVE, .PLAIN_LIVE:
            digest += R.string.localizable.notification_content_live()
        case .SIGNAL_POST, .PLAIN_POST:
            digest += content.content ?? " "
        case .SIGNAL_LOCATION, .PLAIN_LOCATION:
            digest += R.string.localizable.notification_content_location()
        case .APP_CARD:
            if let json = content.content?.data(using: .utf8), let card = try? JSONDecoder.default.decode(AppCardData.self, from: json) {
                digest += "[\(card.title)]"
            }
        default:
            digest += R.string.localizable.notification_content_unknown()
        }
        return digest
    }
    
}
