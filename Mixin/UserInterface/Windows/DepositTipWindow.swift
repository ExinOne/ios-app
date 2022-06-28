import UIKit
import MixinServices

class DepositTipWindow: BottomSheetView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tipsLabel: UILabel!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var assetView: AssetIconView!
    @IBOutlet weak var continueButton: RoundedButton!

    private var canDismiss = false
    private var asset: AssetItem!
    private var timer: Timer?
    private var countDown = 2

    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    override func dismissPopupController(animated: Bool) {
        guard canDismiss else {
            return
        }
        super.dismissPopupController(animated: animated)
    }

    func render(asset: AssetItem, depositEntryIndex: Int) -> DepositTipWindow {
        self.asset = asset
        titleLabel.text = "\(asset.symbol) \(R.string.localizable.deposit())"
        tipsLabel.text = asset.depositTips
        if !asset.depositEntries[depositEntryIndex].tag.isEmpty {
            continueButton.setTitle("\(R.string.localizable.got_it())(\(self.countDown))", for: .normal)
            continueButton.isEnabled = false
            warningLabel.text = R.string.localizable.deposit_account_attention(asset.symbol)
            timer?.invalidate()
            timer = nil
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(countDownAction), userInfo: nil, repeats: true)
        } else {
            continueButton.isEnabled = true
            if asset.reserve.doubleValue > 0 {
                warningLabel.text = R.string.localizable.deposit_attention() +  R.string.localizable.deposit_at_least(asset.reserve, asset.chain?.symbol ?? "")
            } else {
                warningLabel.text = R.string.localizable.deposit_attention()
            }
        }
        assetView.setIcon(asset: asset)
        return self
    }

    @objc func countDownAction() {
        countDown -= 1

        if countDown <= 0 {
            timer?.invalidate()
            timer = nil

            UIView.performWithoutAnimation {
                self.continueButton.isEnabled = true
                self.continueButton.setTitle(R.string.localizable.got_it(), for: .normal)
                self.continueButton.layoutIfNeeded()
            }
        } else {
            UIView.performWithoutAnimation {
                self.continueButton.setTitle("\(R.string.localizable.got_it())(\(self.countDown))", for: .normal)
                self.continueButton.layoutIfNeeded()
            }
        }
    }

    @IBAction func okAction(_ sender: Any) {
        canDismiss = true
        dismissPopupController(animated: true)
    }

    class func instance() -> DepositTipWindow {
        return Bundle.main.loadNibNamed("DepositTipWindow", owner: nil, options: nil)?.first as! DepositTipWindow
    }

}
