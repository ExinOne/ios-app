import UIKit
import MixinServices

class SettingsViewController: SettingsTableViewController {
    
    private let dataSource = SettingsDataSource(sections: [
        SettingsSection(rows: [
            SettingsRow(icon: R.image.setting.ic_category_account(),
                        title: R.string.localizable.account(),
                        accessory: .disclosure),
            SettingsRow(icon: R.image.setting.ic_category_backup(),
                        title: R.string.localizable.chat_backup(),
                        accessory: .disclosure),
            SettingsRow(icon: R.image.setting.ic_category_notification(),
                        title: R.string.localizable.notification_and_confirmation(),
                        accessory: .disclosure),
            SettingsRow(icon: R.image.setting.ic_category_storage(),
                        title: R.string.localizable.data_and_storage_usage(),
                        accessory: .disclosure)
        ]),
        SettingsSection(rows: [
            SettingsRow(icon: R.image.setting.ic_category_appearance(),
                        title: R.string.localizable.appearance(),
                        accessory: .disclosure)
        ]),
//        SettingsSection(rows: [
//            SettingsRow(icon: R.image.setting.ic_category_desktop(),
//                        title: R.string.localizable.mixin_messenger_desktop(),
//                        accessory: .disclosure)
//        ]),
        SettingsSection(rows: [
            SettingsRow(icon: R.image.setting.ic_category_feedback(),
                        title: R.string.localizable.feedback(),
                        accessory: .disclosure)
//            SettingsRow(icon: R.image.setting.ic_category_share(),
//                        title: R.string.localizable.invite_a_friend(),
//                        accessory: .disclosure)
        ]),
        SettingsSection(rows: [
            SettingsRow(icon: R.image.setting.ic_category_about(),
                        title: R.string.localizable.about(),
                        accessory: .disclosure)
        ])
    ])
    
    class func instance() -> UIViewController {
        let vc = SettingsViewController()
        return ContainerViewController.instance(viewController: vc, title: R.string.localizable.settings())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource.tableViewDelegate = self
        dataSource.tableView = tableView
    }
    
}

extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc: UIViewController
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                vc = AccountSettingViewController.instance()
            case 1:
                if FileManager.default.ubiquityIdentityToken == nil {
                    alert(R.string.localizable.backup_disable_hint())
                    return
                } else {
                    vc = BackupViewController.instance()
                }
            case 2:
                vc = NotificationAndConfirmationSettingsViewController.instance()
            default:
                vc = DataAndStorageSettingsViewController.instance()
            }
        case 1:
            vc = AppearanceSettingsViewController.instance()
        case 2:
//            vc = DesktopViewController.instance()
//        case 3:
            if indexPath.row == 0 {
                if let user = UserDAO.shared.getUser(identityNumber: "7000104001") {
                    vc = ConversationViewController.instance(ownerUser: user)
                } else {
//                    DispatchQueue.global().async { [weak self] in
//                        switch UserAPI.showUser(userId: "0f7305a4-a72f-462c-a566-c7e70d8fb7ab") {
//                        case let .success(user):
//                            DispatchQueue.main.async {
//                                let u = UserItem.createUser(from: user)
//                                let vc2 = ConversationViewController.instance(ownerUser: u)
//                                self?.navigationController?.pushViewController(vc2, animated: true)
//                            }
//                        case .failure:
//                            break
//                        }
//                    }
                    return
                }
            } else {
                let content = R.string.localizable.chat_on_mixin_content(myIdentityNumber)
                let controller = UIActivityViewController(activityItems: [content], applicationActivities: nil)
                present(controller, animated: true, completion: nil)
                return
            }
        default:
            vc = AboutViewController.instance()
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
