import UIKit
import MixinServices

class DepositViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var upperDepositFieldView: DepositFieldView!
    @IBOutlet weak var lowerDepositFieldView: DepositFieldView!
    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet weak var warningLabel: UILabel!
    
    private var asset: AssetItem!
    private var depositEntryIndex = 0
    
    private lazy var depositWindow = QrcodeWindow.instance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        container?.setSubtitle(subtitle: asset.symbol)
        view.layoutIfNeeded()
        let entry = asset.depositEntries[depositEntryIndex]
        
        upperDepositFieldView.titleLabel.text = R.string.localizable.address()
        upperDepositFieldView.contentLabel.text = entry.destination
        let nameImage = UIImage(qrcode: entry.destination, size: upperDepositFieldView.qrCodeImageView.bounds.size)
        upperDepositFieldView.qrCodeImageView.image = nameImage
        upperDepositFieldView.assetIconView.setIcon(asset: asset)
        upperDepositFieldView.shadowView.hasLowerShadow = true
        upperDepositFieldView.delegate = self

        if !entry.tag.isEmpty {
            if asset.usesTag {
                lowerDepositFieldView.titleLabel.text = R.string.localizable.tag()
            } else {
                lowerDepositFieldView.titleLabel.text = R.string.localizable.withdrawal_memo()
            }
            lowerDepositFieldView.contentLabel.text = entry.tag
            let memoImage = UIImage(qrcode: entry.tag, size: lowerDepositFieldView.qrCodeImageView.bounds.size)
            lowerDepositFieldView.qrCodeImageView.image = memoImage
            lowerDepositFieldView.assetIconView.setIcon(asset: asset)
            lowerDepositFieldView.shadowView.hasLowerShadow = false
            lowerDepositFieldView.delegate = self
            warningLabel.text = R.string.localizable.deposit_account_attention(asset.symbol)
        } else {
            lowerDepositFieldView.isHidden = true
            if asset.reserve.doubleValue > 0 {
                warningLabel.text = R.string.localizable.deposit_attention() +  R.string.localizable.deposit_at_least(asset.reserve, asset.chain?.symbol ?? "")
            } else {
                warningLabel.text = R.string.localizable.deposit_attention()
            }
        }

        hintLabel.text = asset.depositTips

        DepositTipWindow.instance().render(asset: asset, depositEntryIndex: depositEntryIndex).presentPopupControllerAnimated()
    }
    
    class func instance(asset: AssetItem, depositEntryIndex: Int) -> UIViewController {
        let vc = R.storyboard.wallet.deposit()!
        vc.asset = asset
        vc.depositEntryIndex = depositEntryIndex
        return ContainerViewController.instance(viewController: vc, title: R.string.localizable.deposit())
    }
    
}

extension DepositViewController: ContainerViewControllerDelegate {
    
    var prefersNavigationBarSeparatorLineHidden: Bool {
        return true
    }
    
    func imageBarRightButton() -> UIImage? {
        R.image.ic_titlebar_help()
    }
    
    func barRightButtonTappedAction() {
        UIApplication.shared.openURL(url: "https://mixinmessenger.zendesk.com/hc/articles/360018789931")
    }
    
}

extension DepositViewController: DepositFieldViewDelegate {
    
    func depositFieldViewDidCopyContent(_ view: DepositFieldView) {
        showAutoHiddenHud(style: .notification, text: R.string.localizable.copied())
    }
    
    func depositFieldViewDidSelectShowQRCode(_ view: DepositFieldView) {
        depositWindow.render(title: view.titleLabel.text ?? "",
                             content: view.contentLabel.text ?? "",
                             asset: asset)
        depositWindow.presentView()
    }
}
