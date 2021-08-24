import UIKit
import MixinServices

protocol PinMessagesPreviewViewControllerDelegate: AnyObject {
    func pinMessagesPreviewViewController(_ controller: PinMessagesPreviewViewController, needsShowMessage messageId: String)
}

final class PinMessagesPreviewViewController: StaticMessagesViewController {
    
    weak var delegate: PinMessagesPreviewViewControllerDelegate?
    
    private let conversationId: String
    private let bottomBarViewHeight: CGFloat = 50
    
    private var pinnedMessageItems: [MessageItem] = []
    
    private lazy var bottomBarView: UIView = {
        let button = UIButton()
        button.setTitle(R.string.localizable.chat_unpin_all_messages(), for: .normal)
        button.setTitleColor(R.color.theme(), for: .normal)
        button.addTarget(self, action: #selector(unpinAllAction), for: .touchUpInside)
        let view = UIView()
        view.backgroundColor = R.color.background()
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(bottomBarViewHeight)
        }
        return view
    }()
    
    init(conversationId: String) {
        self.conversationId = conversationId
        super.init(audioManager: PinAudioMessagePlayingManager())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let layoutWidth = AppDelegate.current.mainWindow.bounds.width
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.pinnedMessageItems = PinMessageDAO.shared.messageItems(conversationId: self.conversationId)
            let (dates, viewModels) = self.categorizedViewModels(with: self.pinnedMessageItems, fits: layoutWidth)
            let isAdmin = ParticipantDAO.shared.isAdmin(conversationId: self.conversationId, userId: myUserId)
            DispatchQueue.main.async {
                if isAdmin {
                    let safeAreaInsets = AppDelegate.current.mainWindow.safeAreaInsets
                    self.view.addSubview(self.bottomBarView)
                    self.bottomBarView.snp.makeConstraints { make in
                        make.left.right.equalToSuperview()
                        make.height.equalTo(safeAreaInsets.bottom + self.bottomBarViewHeight)
                        make.bottom.equalTo(-safeAreaInsets.top)
                    }
                    self.tableViewBottomConstraint.constant = self.tableViewBottomConstraint.constant + self.bottomBarViewHeight
                }
                self.titleLabel.text = R.string.localizable.chat_pinned_messages_count(viewModels.count)
                self.dates = dates
                self.viewModels = viewModels
                self.tableView.reloadData()
            }
        }
    }
    
}

extension PinMessagesPreviewViewController {
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
        guard let cell = cell as? MessageCell,
              let viewModel = viewModel(at: indexPath), viewModel.message.userId != myUserId else {
            return
        }
        let button = UIButton()
        button.addTarget(self, action: #selector(showMessageAction(sender:)), for: .touchUpInside)
        button.tag =  indexPath.row + 999
        button.setImage(R.image.ic_pin_right_arrow(), for: .normal)
        cell.contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.centerY.equalTo(cell.backgroundImageView)
            make.left.equalTo(cell.backgroundImageView.snp.right)
            make.height.width.equalTo(36)
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        super.tableView(tableView, didEndDisplaying: cell, forRowAt: indexPath)
        guard let view = cell.viewWithTag(indexPath.row + 999), view is UIButton else {
            return
        }
        view.removeFromSuperview()
    }
    
}

extension PinMessagesPreviewViewController {
    
    @objc private func unpinAllAction() {
        let controller = UIAlertController(title: R.string.localizable.chat_alert_unpin_all_messages(), message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: R.string.localizable.dialog_button_cancel(), style: .cancel, handler: nil)
        let unpinAction = UIAlertAction(title: R.string.localizable.menu_unpin(), style: .default) { _ in
            self.queue.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.pinnedMessageItems.forEach({ PinMessageDAO.shared.unpinMessage(fullMessage: $0) })
                DispatchQueue.main.async {
                    self.dismissAsChild(completion: nil)
                }
            }
        }
        controller.addAction(cancelAction)
        controller.addAction(unpinAction)
        present(controller, animated: true, completion: nil)
    }
    
    @objc private func showMessageAction(sender: UIButton) {
        guard let cell = sender.superview?.superview as? MessageCell,
              let indexPath = tableView.indexPath(for: cell),
              let viewModel = viewModel(at: indexPath) else {
            return
        }
        delegate?.pinMessagesPreviewViewController(self, needsShowMessage: viewModel.message.messageId)
    }
    
}
