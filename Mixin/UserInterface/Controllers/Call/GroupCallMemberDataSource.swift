import UIKit
import MixinServices

class GroupCallMemberDataSource: NSObject {
    
    // Instance of this class is designed to be the data source of member's grid in CallViewController
    // Compared with members stored in GroupCallMembersManager, members here may not actually in the call
    // That is to say, a member which is invited but not yet connected, needs to be shown in the grid, but
    // he's not in the call, therefore you won't find him in GroupCallMembersManager
    
    static let visibleMembersDidChangeNotification = Notification.Name("one.mixin.messenger.GroupCall.VisibleMembersDidChange")
    
    weak var collectionView: UICollectionView? {
        didSet {
            oldValue?.dataSource = nil
            if let collectionView = collectionView {
                collectionView.dataSource = self
                collectionView.reloadData()
            }
        }
    }
    
    private let conversationId: String
    private let debugWithNumerousMembers = false
    
    // This var is in sync with members
    private(set) var memberUserIds: Set<String>
    private(set) var members: [UserItem]
    private(set) var invitingMemberUserIds: Set<String>
    
    private var audioLevels: [String: Double] = [:] // key is user id
    
    private weak var participantsCountLabel: UILabel?
    
    init(conversationId: String, members: [UserItem], invitingMemberUserIds: Set<String>) {
        Logger.call.info(category: "GroupCallMemberDataSource", message: "init with members: \(members.map(\.fullName)), inviting: \(invitingMemberUserIds)")
        self.members = members
        self.invitingMemberUserIds = invitingMemberUserIds
        self.conversationId = conversationId
        self.memberUserIds = Set(members.map(\.userId))
        super.init()
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector: #selector(callServiceMutenessDidChange),
                           name: CallService.mutenessDidChangeNotification,
                           object: nil)
        center.addObserver(self,
                           selector: #selector(updateWithPolledPeers(_:)),
                           name: GroupCallMembersManager.membersDidChangeNotification,
                           object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func reportStartInviting(_ members: [UserItem]) {
        Logger.call.info(category: "GroupCallMemberDataSource", message: "start inviting: \(members.map(\.fullName))")
        let filtered = members.filter { (member) -> Bool in
            !self.memberUserIds.contains(member.userId)
        }
        for member in filtered {
            memberUserIds.insert(member.userId)
            invitingMemberUserIds.insert(member.userId)
        }
        if !filtered.isEmpty {
            let indexPaths = (self.members.count..<(self.members.count + filtered.count))
                .map(self.indexPath(forMemberAt:))
            self.members.append(contentsOf: filtered)
            collectionView?.insertItems(at: indexPaths)
            participantsCountLabel?.text = R.string.localizable.group_call_participants_count(self.members.count)
            NotificationCenter.default.post(name: Self.visibleMembersDidChangeNotification, object: self)
        }
    }
    
    func reportMemberDidConnected(_ member: UserItem) {
        Logger.call.info(category: "GroupCallMemberDataSource", message: "\(member.fullName) did connected")
        invitingMemberUserIds.remove(member.userId)
        if let index = members.firstIndex(where: { $0.userId == member.userId }) {
            let indexPath = self.indexPath(forMemberAt: index)
            UIView.performWithoutAnimation {
                collectionView?.reloadItems(at: [indexPath])
                participantsCountLabel?.text = R.string.localizable.group_call_participants_count(self.members.count)
            }
        } else {
            let indexPath = self.indexPath(forMemberAt: members.count)
            members.append(member)
            memberUserIds.insert(member.userId)
            collectionView?.insertItems(at: [indexPath])
            participantsCountLabel?.text = R.string.localizable.group_call_participants_count(self.members.count)
        }
        NotificationCenter.default.post(name: Self.visibleMembersDidChangeNotification, object: self)
    }
    
    func reportMemberWithIdDidDisconnected(_ id: String) {
        Logger.call.info(category: "GroupCallMemberDataSource", message: "\(id) did disconnected")
        invitingMemberUserIds.remove(id)
        memberUserIds.remove(id)
        if let index = members.firstIndex(where: { $0.userId == id }) {
            let indexPath = self.indexPath(forMemberAt: index)
            members.remove(at: index)
            collectionView?.deleteItems(at: [indexPath])
            participantsCountLabel?.text = R.string.localizable.group_call_participants_count(self.members.count)
            NotificationCenter.default.post(name: Self.visibleMembersDidChangeNotification, object: self)
        }
    }
    
    func report(audioLevels: [String: Double]) {
        self.audioLevels = audioLevels
        for indexPath in collectionView?.indexPathsForVisibleItems ?? [] {
            guard let member = member(at: indexPath) else {
                continue
            }
            guard let cell = collectionView?.cellForItem(at: indexPath) as? CallMemberCell else {
                continue
            }
            cell.isSpeaking = isMemberSpeaking(userId: member.userId)
        }
    }
    
    func member(at indexPath: IndexPath) -> UserItem? {
        guard indexPath.item > 0 else {
            // Add member button
            return nil
        }
        let index: Int
        if debugWithNumerousMembers {
            index = (indexPath.item - 1) % members.count
        } else {
            index = indexPath.item - 1
        }
        if index < members.count {
            return members[index]
        } else {
            return nil
        }
    }
    
    @objc private func updateWithPolledPeers(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        guard let conversationId = userInfo[GroupCallMembersManager.UserInfoKey.conversationId] as? String else {
            return
        }
        guard conversationId == self.conversationId else {
            return
        }
        guard let remoteUserIds = userInfo[GroupCallMembersManager.UserInfoKey.userIds] as? [String] else {
            return
        }
        let remoteIds = Set(remoteUserIds)
        DispatchQueue.main.async {
            var indexPathsToRemove: [IndexPath] = []
            for (index, member) in self.members.enumerated().reversed() {
                guard !remoteIds.contains(member.userId) && member.userId != myUserId else {
                    continue
                }
                Logger.call.info(category: "GroupCallMemberDataSource", message: "remove zombie: \(member.fullName), at: \(index)")
                self.invitingMemberUserIds.remove(member.userId)
                self.memberUserIds.remove(member.userId)
                self.members.remove(at: index)
                let indexPath = self.indexPath(forMemberAt: index)
                indexPathsToRemove.append(indexPath)
            }
            self.collectionView?.deleteItems(at: indexPathsToRemove)
            self.participantsCountLabel?.text = R.string.localizable.group_call_participants_count(self.members.count)
            NotificationCenter.default.post(name: Self.visibleMembersDidChangeNotification, object: self)
        }
    }
    
    @objc private func callServiceMutenessDidChange() {
        guard CallService.shared.isMuted, let index = members.firstIndex(where: { $0.userId == myUserId }) else {
            return
        }
        let indexPath = self.indexPath(forMemberAt: index)
        guard let cell = collectionView?.cellForItem(at: indexPath) as? CallMemberCell else {
            return
        }
        cell.isSpeaking = false
    }
    
    private func indexPath(forMemberAt index: Int) -> IndexPath {
        IndexPath(item: index + 1, section: 0) // +1 for the add button
    }
    
    private func isMemberSpeaking(userId: String) -> Bool {
        (audioLevels[userId] ?? 0) > 0.01
    }
    
}

extension GroupCallMemberDataSource: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if debugWithNumerousMembers {
            return (members.count * 10) + 1
        } else {
            return members.count + 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.call_member, for: indexPath)!
        if indexPath.item == 0 {
            cell.avatarWrapperView.backgroundColor = R.color.button_background_secondary()
            cell.avatarImageView.imageView.contentMode = .center
            cell.avatarImageView.image = R.image.ic_title_add()
            cell.connectingView.isHidden = true
            cell.label.text = R.string.localizable.action_add()
        } else {
            cell.avatarWrapperView.backgroundColor = .background
            cell.avatarImageView.imageView.contentMode = .scaleAspectFill
            if let member = self.member(at: indexPath) {
                cell.avatarImageView.setImage(with: member)
                cell.connectingView.isHidden = !invitingMemberUserIds.contains(member.userId)
                cell.label.text = member.fullName
                cell.isSpeaking = isMemberSpeaking(userId: member.userId)
            }
        }
        cell.hasBiggerLayout = false
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
}
