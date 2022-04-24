import UIKit
import Photos
import MixinServices

class QrcodeWindow: BottomSheetView {
    
    @IBOutlet weak var qrcodeImageView: UIImageView!
    @IBOutlet weak var avatarImageView: AvatarImageView!
    @IBOutlet weak var assetIconView: AssetIconView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var receiveMoneyImageView: UIImageView!
    
    @IBOutlet weak var qrcodeView: UIView!
    
    var isShowingMyQrCode = false
    
    func render(conversation: ConversationItem) {
        guard let conversationCodeUrl = conversation.codeUrl else {
            return
        }
        render(title: conversation.name,
               description: R.string.localizable.group_qr_code_prompt(),
               qrcode: conversationCodeUrl,
               qrcodeForegroundColor: .black)
        avatarImageView.isHidden = false
        assetIconView.isHidden = true
        receiveMoneyImageView.isHidden = true
        avatarImageView.setGroupImage(conversation: conversation)
    }
    
    func render(title: String, description: String, account: Account) {
        render(title: R.string.localizable.my_QR_Code(),
               description: R.string.localizable.scan_code_add_me(),
               qrcode: account.code_url,
               qrcodeForegroundColor: .systemTint)
        avatarImageView.isHidden = false
        assetIconView.isHidden = true
        receiveMoneyImageView.isHidden = true
        avatarImageView.setImage(with: account)
        isShowingMyQrCode = true
    }
    
    func renderMoneyReceivingCode(account: Account) {
        render(title: R.string.localizable.receive_Money(),
               description: R.string.localizable.transfer_qrcode_prompt(),
               qrcode: "mixin://transfer/\(account.user_id)",
               qrcodeForegroundColor: .black)
        avatarImageView.isHidden = false
        assetIconView.isHidden = true
        receiveMoneyImageView.isHidden = false
        avatarImageView.setImage(with: account)
    }
    
    func render(title: String, content: String, asset: AssetItem) {
        render(title: title,
               description: content,
               qrcode: content,
               qrcodeForegroundColor: .black)
        avatarImageView.isHidden = true
        assetIconView.isHidden = false
        receiveMoneyImageView.isHidden = true
        assetIconView.setIcon(asset: asset)
    }
    
    private func render(title: String, description: String, qrcode: String, qrcodeForegroundColor: UIColor) {
        titleLabel.text = title
        descriptionLabel.text = description
        qrcodeImageView.image = UIImage(qrcode: qrcode, size: qrcodeImageView.frame.size, foregroundColor: qrcodeForegroundColor)
    }
    
    @IBAction func dismissAction(_ sender: Any) {
        dismissView()
    }
    
    @IBAction func saveAction(_ sender: Any) {
        PHPhotoLibrary.checkAuthorization { [weak self](authorized) in
            guard let weakSelf = self else {
                return
            }
            if authorized {
                weakSelf.performSavingToLibrary()
            } else {
                weakSelf.dismissPopupControllerAnimated()
            }
        }
    }
    
    private func performSavingToLibrary() {
        let renderer = UIGraphicsImageRenderer(bounds: qrcodeView.bounds)
        let image = renderer.image { (context) in
            qrcodeView.layer.render(in: context.cgContext)
        }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { [weak self](success, error) in
            DispatchQueue.main.async {
                self?.dismissPopupControllerAnimated()
                if success {
                    showAutoHiddenHud(style: .notification, text: R.string.localizable.saved())
                } else {
                    showAutoHiddenHud(style: .notification, text: R.string.localizable.operation_failed())
                }
            }
        })
    }
    
    class func instance() -> QrcodeWindow {
        return Bundle.main.loadNibNamed("QrcodeWindow", owner: nil, options: nil)?.first as! QrcodeWindow
    }
    
}
