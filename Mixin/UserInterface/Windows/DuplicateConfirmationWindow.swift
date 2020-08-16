import Foundation
import MixinServices

class DuplicateConfirmationWindow: BottomSheetView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tipsLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var amountExchangeLabel: UILabel!
    @IBOutlet weak var assetIconView: AssetIconView!
    @IBOutlet weak var confirmButton: RoundedButton!

    private weak var textfield: UITextField?
    private var asset: AssetItem!
    private var amount = ""
    private var memo = ""
    private var action: PayWindow.PinAction!
    private var error: String?
    private var fiatMoneyAmount: String?
    private var timer: Timer?
    private var countDown = 3

    deinit {
        timer?.invalidate()
        timer = nil
    }

    func render(traceCreatedAt: String, asset: AssetItem, action: PayWindow.PinAction, amount: String, memo: String, error: String? = nil, fiatMoneyAmount: String? = nil, textfield: UITextField? = nil) -> DuplicateConfirmationWindow {
        self.asset = asset
        self.action = action
        self.amount = amount
        self.memo = memo
        self.error = error
        self.fiatMoneyAmount = fiatMoneyAmount
        self.textfield = textfield

        let amountToken = CurrencyFormatter.localizedString(from: amount, locale: .current, format: .precision, sign: .whenNegative, symbol: .custom(asset.symbol)) ?? amount
        let amountExchange = CurrencyFormatter.localizedPrice(price: amount, priceUsd: asset.priceUsd)
        if let fiatMoneyAmount = fiatMoneyAmount {
            amountLabel.text = fiatMoneyAmount + " " + Currency.current.code
            amountExchangeLabel.text = amountToken
        } else {
            amountLabel.text = amountToken
            amountExchangeLabel.text = amountExchange
        }

        switch action {
        case let .transfer(_, user, _):
            titleLabel.text = R.string.localizable.transfer_duplicate_title()
            tipsLabel.text = R.string.localizable.transfer_duplicate_prompt(amountLabel.text ?? "", user.fullName, traceCreatedAt.toUTCDate().simpleTimeAgo())
        case let .withdraw(_, address, _, _):
            titleLabel.text = R.string.localizable.withdraw_duplicate_title()
            tipsLabel.text = R.string.localizable.withdraw_duplicate_prompt(amountLabel.text ?? "", address.fullAddress.toSimpleKey(), traceCreatedAt.toUTCDate().simpleTimeAgo())
        default:
            break
        }

        assetIconView.setIcon(asset: asset)

        confirmButton.setTitle("\(R.string.localizable.action_continue())(\(self.countDown))", for: .normal)
        confirmButton.isEnabled = false
        timer?.invalidate()
        timer = nil
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(countDownAction), userInfo: nil, repeats: true)
        return self
    }

    @IBAction func continueAction(_ sender: Any) {
        switch action! {
        case let .transfer(_, user, _):
            break
        case let .withdraw(_, address, _, _):
            break
        default:
            break
        }
    }

    @IBAction func dismissAction(_ sender: Any) {
        dismissPopupControllerAnimated()
    }

    @objc func countDownAction() {
        countDown -= 1

        if countDown <= 0 {
            timer?.invalidate()
            timer = nil

            UIView.performWithoutAnimation {
                self.confirmButton.isEnabled = true
                self.confirmButton.setTitle(R.string.localizable.action_continue(), for: .normal)
                self.confirmButton.layoutIfNeeded()
            }
        } else {
            UIView.performWithoutAnimation {
                self.confirmButton.setTitle("\(R.string.localizable.action_continue())(\(self.countDown))", for: .normal)
                self.confirmButton.layoutIfNeeded()
            }
        }
    }

    static func instance() -> DuplicateConfirmationWindow {
        return Bundle.main.loadNibNamed("DuplicateConfirmationWindow", owner: nil, options: nil)?.first as! DuplicateConfirmationWindow
    }
}
