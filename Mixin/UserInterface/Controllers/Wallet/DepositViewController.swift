import UIKit
import MixinServices

class DepositViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var upperDepositFieldView: DepositFieldView!
    @IBOutlet weak var lowerDepositFieldView: DepositFieldView!
    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var activityIndicatorView: ActivityIndicatorView!
    
    private var asset: AssetItem!
    private var hasDepositChooseNetworkWindowPresented = false
    
    private lazy var depositWindow = QrcodeWindow.instance()
    
    private weak var job: RefreshAssetsJob?
    
    deinit {
        job?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        container?.setSubtitle(subtitle: asset.symbol)
        view.layoutIfNeeded()
        
        if let entry = asset.preferredDepositEntry, let chain = asset.chain {
            stopLoading()
            show(entry: entry)
            showDepositChooseNetworkWindowIfNeeded(chain: chain)
        } else {
            startLoading()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(assetsDidChange(_:)), name: AssetDAO.assetsDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(chainsDidChange(_:)), name: ChainDAO.chainsDidChangeNotification, object: nil)
        let job = RefreshAssetsJob(request: .asset(id: asset.assetId, untilDepositEntriesNotEmpty: true))
        self.job = job
        ConcurrentJobQueue.shared.addJob(job: job)
    }
    
    class func instance(asset: AssetItem) -> UIViewController {
        let vc = R.storyboard.wallet.deposit()!
        vc.asset = asset
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
        UIApplication.shared.openURL(url: .deposit)
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

extension DepositViewController {
    
    @objc private func assetsDidChange(_ notification: Notification) {
        guard let id = notification.userInfo?[AssetDAO.UserInfoKey.assetId] as? String else {
            return
        }
        guard id == asset.assetId else {
            return
        }
        reloadAsset()
    }
    
    @objc private func chainsDidChange(_ notification: Notification) {
        guard let id = notification.userInfo?[ChainDAO.UserInfoKey.chainId] as? String else {
            return
        }
        guard id == asset.chainId else {
            return
        }
        reloadAsset()
    }
    
    private func reloadAsset() {
        let assetId = asset.assetId
        DispatchQueue.global().async { [weak self] in
            guard let asset = AssetDAO.shared.getAsset(assetId: assetId), let chain = asset.chain else {
                return
            }
            DispatchQueue.main.sync {
                guard let self = self else {
                    return
                }
                self.asset = asset
                if let entry = asset.preferredDepositEntry {
                    self.stopLoading()
                    UIView.performWithoutAnimation {
                        self.show(entry: entry)
                    }
                    self.showDepositChooseNetworkWindowIfNeeded(chain: chain)
                }
            }
        }
    }
    
    private func show(entry: Asset.DepositEntry) {
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
    }
    
    private func showDepositChooseNetworkWindowIfNeeded(chain: Chain) {
        guard !hasDepositChooseNetworkWindowPresented else {
            return
        }
        hasDepositChooseNetworkWindowPresented = true
        DepositChooseNetworkWindow.instance().render(asset: asset, chain: chain).presentPopupControllerAnimated()
    }
    
    private func startLoading() {
        loadingView.isHidden = false
        activityIndicatorView.startAnimating()
    }
    
    private func stopLoading() {
        loadingView.isHidden = true
        activityIndicatorView.stopAnimating()
    }
    
}
