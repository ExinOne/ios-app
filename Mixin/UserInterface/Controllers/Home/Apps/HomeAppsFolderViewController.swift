import UIKit

protocol HomeAppsFolderViewControllerDelegate: AnyObject {
    func homeAppsFolderViewControllerOpenAnimationWillStart(_ controller: HomeAppsFolderViewController)
    func homeAppsFolderViewControllerDidEnterEditingMode(_ controller: HomeAppsFolderViewController)
    func homeAppsFolderViewController(_ controller: HomeAppsFolderViewController, didChangeName name: String)
    func homeAppsFolderViewController(_ controller: HomeAppsFolderViewController, didSelectApp app: HomeApp)
    func homeAppsFolderViewController(_ controller: HomeAppsFolderViewController, didBeginFolderDragOutWithTransfer transfer: HomeAppsDragInteractionTransfer)
    func homeAppsFolderViewController(_ controller: HomeAppsFolderViewController, dismissAnimationWillStartOnPage page: Int, updatedPages: [[HomeApp]])
    func homeAppsFolderViewControllerDismissAnimationDidFinish(_ controller: HomeAppsFolderViewController)
}

class HomeAppsFolderViewController: UIViewController {
    
    weak var delegate: HomeAppsFolderViewControllerDelegate?
    
    @IBOutlet weak var backgroundView: UIVisualEffectView!
    @IBOutlet weak var textFieldContainer: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var containerViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerViewTrailingConstraint: NSLayoutConstraint!
    
    var openAnimationDidEnd: (() -> Void)?
    var folder: HomeAppFolder!
    var sourceFrame: CGRect!
    var startInRename: Bool = false
    var currentPage: Int = 0
    var dragInteractionTransfer: HomeAppsDragInteractionTransfer?
    
    private var homeAppsManager: HomeAppsManager!
    private var containerViewOriginalFrame: CGRect!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if ScreenWidth.current <= .short {
            containerViewLeadingConstraint.constant = 20
            containerViewTrailingConstraint.constant = 20
        }
        textField.text = folder.name
        leaveTextFieldEditingMode()
        homeAppsManager = HomeAppsManager(viewController: self,
                                          candidateCollectionView: collectionView,
                                          items: folder.pages.map { $0.map { .app($0) } })
        homeAppsManager.delegate = self
        if homeAppsManager.items.count == 1 {
            pageControl.isHidden = true
        } else {
            pageControl.alpha = 0
            pageControl.isHidden = false
            pageControl.numberOfPages = homeAppsManager.items.count
        }
        if let transfer = dragInteractionTransfer {
            homeAppsManager.perform(transfer: transfer)
        }
        if isEditing {
            let indexPath = IndexPath(item: currentPage, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        }
        prepareForAnimateIn()
        dragInteractionTransfer = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.homeAppsFolderViewControllerOpenAnimationWillStart(self)
        animateIn()
        if isEditing {
            homeAppsManager.enterEditingMode(occurHaptic: false)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            backgroundView.effect = UserInterfaceStyle.current == .light ? .darkBlur : .lightBlur
        }
    }
    
    @IBAction func clearTextField(_ sender: UIButton) {
        textField.text = ""
        textField.becomeFirstResponder()
    }
    
    @IBAction func dismissAction() {
        dismiss()
    }
    
}

extension HomeAppsFolderViewController {
    
    private func dismiss(completion: (() -> Void)? = nil) {
        textField.resignFirstResponder()
        homeAppsManager.leaveEditingMode()
        let pages: [[HomeApp]] = homeAppsManager.items.map { $0.compactMap { $0.app } }
        delegate?.homeAppsFolderViewController(self, dismissAnimationWillStartOnPage: pageControl.currentPage, updatedPages: pages)
        animateOut(completion: completion)
    }
    
    private func leaveTextFieldEditingMode() {
        textField.isEnabled = false
        clearButton.alpha = 0
        textFieldContainer.backgroundColor = textFieldContainer.backgroundColor?.withAlphaComponent(0)
    }
    
    private func enterTextFieldEditingMode() {
        textField.isEnabled = true
        clearButton.alpha = 1
        textFieldContainer.backgroundColor = textFieldContainer.backgroundColor?.withAlphaComponent(0.4)
    }
    
    private func prepareForAnimateIn() {
        view.layoutIfNeeded()
        textField.alpha = 0
        backgroundView.effect = nil
        containerViewOriginalFrame = containerView.frame
        containerView.transform = CGAffineTransform.transform(from: containerView.frame, to: sourceFrame)
        containerView.alpha = 0
    }
    
    private func animateIn() {
        let animation = UIViewPropertyAnimator(duration: 0.35, controlPoint1: CGPoint(x: 0.37, y: 0.31), controlPoint2: CGPoint(x: 0, y: 1)) {
            self.view.layoutIfNeeded()
            self.textField.alpha = 1
            self.containerView.transform = CGAffineTransform.identity
            self.containerView.alpha = 1
            self.homeAppsManager.updateFolderDragOutFlags()
            self.backgroundView.effect = UserInterfaceStyle.current == .light ? .darkBlur : .lightBlur
        }
        animation.addCompletion { _ in
            self.openAnimationDidEnd?()
            UIViewPropertyAnimator(duration: 0.5, curve: .easeOut) {
                self.pageControl.alpha = 1
                if self.isEditing {
                    self.enterTextFieldEditingMode()
                    if self.startInRename {
                        self.textField.becomeFirstResponder()
                        self.textField.selectAll(nil)
                    }
                }
            }.startAnimation()
        }
        animation.startAnimation()
    }
    
    private func animateOut(completion: (() -> Void)?) {
        let animation = UIViewPropertyAnimator(duration: 0.35, controlPoint1: CGPoint(x: 0.37, y: 0.13), controlPoint2: CGPoint(x: 0, y: 1)) {
            self.view.layoutIfNeeded()
            self.textField.alpha = 0
            self.leaveTextFieldEditingMode()
            self.containerView.transform = CGAffineTransform.transform(from: self.containerView.frame, to: self.sourceFrame)
            self.containerView.alpha = 0
            self.backgroundView.effect = nil
        }
        animation.addCompletion { _ in
            self.delegate?.homeAppsFolderViewControllerDismissAnimationDidFinish(self)
            completion?()
        }
        animation.startAnimation()
    }
    
}

extension HomeAppsFolderViewController: HomeAppsManagerDelegate {
    
    func homeAppsManagerDidEnterEditingMode(_ manager: HomeAppsManager) {
        if !isEditing {
            delegate?.homeAppsFolderViewControllerDidEnterEditingMode(self)
            isEditing = true
        }
        if pageControl.isHidden {
            pageControl.isHidden = false
            pageControl.alpha = 0
        }
        UIView.animate(withDuration: 0.25) {
            self.enterTextFieldEditingMode()
            self.pageControl.numberOfPages = self.homeAppsManager.items.count
            self.pageControl.alpha = 1
        }
    }
    
    func homeAppsManagerDidLeaveEditingMode(_ manager: HomeAppsManager) {
        if !textField.hasText {
            textField.text = folder.name
        } else if let text = textField.text {
            folder.name = text
            delegate?.homeAppsFolderViewController(self, didChangeName: text)
        }
        leaveTextFieldEditingMode()
    }
    
    func homeAppsManager(_ manager: HomeAppsManager, didSelectApp app: HomeApp) {
        dismiss { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.homeAppsFolderViewController(self, didSelectApp: app)
        }
    }
    
    func homeAppsManager(_ manager: HomeAppsManager, didMoveToPage page: Int) {
        pageControl.currentPage = page
    }
    
    func homeAppsManager(_ manager: HomeAppsManager, didUpdatePageCount pageCount: Int) {
        pageControl.numberOfPages = pageCount
    }
    
    func homeAppsManager(_ manager: HomeAppsManager, didBeginFolderDragOutWithTransfer transfer: HomeAppsDragInteractionTransfer) {
        dismissAction()
        delegate?.homeAppsFolderViewController(self, didBeginFolderDragOutWithTransfer: transfer)
    }
    
    func homeAppsManagerDidUpdateItems(_ manager: HomeAppsManager) {
        
    }
    
}

extension HomeAppsFolderViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if !textField.hasText {
            textField.text = folder.name
        } else if let text = textField.text {
            folder.name = text
            delegate?.homeAppsFolderViewController(self, didChangeName: text)
        }
        return true
    }
    
}
