import Foundation
import MixinServices

class DuplicateConfirmationWindow: AssetConfirmationWindow {

    func render(traceCreatedAt: String, asset: AssetItem, action: PayWindow.PinAction, amount: String, memo: String, fiatMoneyAmount: String? = nil, completion: @escaping CompletionHandler) -> BottomSheetView {
        let result = super.render(asset: asset, amount: amount, memo: memo, fiatMoneyAmount: fiatMoneyAmount, completion: completion)
        switch action {
        case let .transfer(_, user, _):
            titleLabel.text = R.string.localizable.duplicate_Transfer_Confirmation()
            tipsLabel.text = R.string.localizable.wallet_transfer_recent_tip(amountLabel.text ?? "", user.fullName, traceCreatedAt.toUTCDate().simpleTimeAgo())
        case let .withdraw(_, address, _, _):
            titleLabel.text = R.string.localizable.duplicate_Transfer_Confirmation()
            tipsLabel.text = R.string.localizable.wallet_withdrawal_recent_tip(amountLabel.text ?? "", address.fullAddress.toSimpleKey(), traceCreatedAt.toUTCDate().simpleTimeAgo())
        default:
            break
        }
        return result
    }

    static func instance() -> DuplicateConfirmationWindow {
        return Bundle.main.loadNibNamed("DuplicateConfirmationWindow", owner: nil, options: nil)?.first as! DuplicateConfirmationWindow
    }
}
