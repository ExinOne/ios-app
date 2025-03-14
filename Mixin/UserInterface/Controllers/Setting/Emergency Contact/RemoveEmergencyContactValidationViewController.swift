import UIKit
import MixinServices

class RemoveEmergencyContactValidationViewController: PinValidationViewController {
    
    convenience init() {
        self.init(nib: R.nib.pinValidationView)
        transitioningDelegate = presentationManager
        modalPresentationStyle = .custom
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionLabel.text = R.string.localizable.emergency_pin_protection_hint()
    }
    
    override func validate(pin: String) {
        EmergencyAPI.delete(pin: pin) { [weak self] (result) in
            guard let weakSelf = self else {
                return
            }
            weakSelf.loadingIndicator.stopAnimating()
            switch result {
            case .success(let account):
                LoginManager.shared.setAccount(account)
                weakSelf.dismiss(animated: true, completion: nil)
            case .failure(let error):
                weakSelf.handle(error: error)
            }
        }
    }
    
}
