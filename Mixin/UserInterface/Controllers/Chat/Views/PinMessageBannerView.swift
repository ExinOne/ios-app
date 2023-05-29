import UIKit

protocol PinMessageBannerViewDelegate: AnyObject {
    func pinMessageBannerViewDidTapPin(_ view: PinMessageBannerView)
    func pinMessageBannerViewDidTapClose(_ view: PinMessageBannerView)
    func pinMessageBannerViewDidTapPreview(_ view: PinMessageBannerView)
}

final class PinMessageBannerView: UIView {
    
    weak var delegate: PinMessageBannerViewDelegate?
    
    @IBOutlet weak var pinButton: UIButton!
    @IBOutlet weak var wrapperButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBAction func tapCloseAction(_ sender: Any) {
        delegate?.pinMessageBannerViewDidTapClose(self)
    }
    
    @IBAction func tapPinAction(_ sender: Any) {
        delegate?.pinMessageBannerViewDidTapPin(self)
    }
    
    @IBAction func tapMessageAction(_ sender: Any) {
        delegate?.pinMessageBannerViewDidTapPreview(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        messageLabel.font = MessageFontSet.cardSubtitle.scaled
    }
    
}

extension PinMessageBannerView {
    
    func update(preview: String) {
        closeButton.isHidden = false
        wrapperButton.isHidden = false
        messageLabel.isHidden = false
        messageLabel.text = preview
    }
    
    func hideMessagePreview() {
        closeButton.isHidden = true
        wrapperButton.isHidden = true
        messageLabel.isHidden = true
    }
    
}

