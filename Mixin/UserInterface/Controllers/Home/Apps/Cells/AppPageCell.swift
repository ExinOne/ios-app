import UIKit

protocol AppPageCellDelegate: AnyObject {
    func appPageCell(_ pageCell: AppPageCell, didSelect cell: HomeAppCell)
}

class AppPageCell: UICollectionViewCell {
    
    weak var delegate: AppPageCellDelegate?
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var mode: HomeAppsMode = .regular {
        didSet {
            updateLayout()
        }
    }
    var items: [HomeAppItem] = []
    var draggedItem: HomeAppItem?
    
    private var isEditing = false
    
    func enterEditingMode() {
        guard !isEditing else {
            return
        }
        isEditing = true
        for case let cell as HomeAppCell in collectionView.visibleCells {
            cell.startShaking()
            if let cell = cell as? AppFolderCell {
                cell.moveToFirstAvailablePage()
            }
        }
    }
    
    func leaveEditingMode() {
        guard isEditing else {
            return
        }
        isEditing = false
        for case let cell as HomeAppCell in collectionView.visibleCells {
            cell.stopShaking()
            if let cell = cell as? AppFolderCell {
                cell.leaveEditingMode()
                cell.move(to: 0, animated: true)
            }
        }
    }
    
    func delete(item: HomeAppItem) {
        guard let index = items.firstIndex(where: { $0 == item }),
              let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) else {
            return
        }
        UIView.animate(withDuration: 0.25, animations: {
            cell.contentView.transform = CGAffineTransform.identity.scaledBy(x: 0.0001, y: 0.0001)
        }, completion: { _ in
            self.items.remove(at: index)
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
            }, completion: { _ in
                cell.contentView.transform = .identity
            })
        })
    }
    
    private func updateLayout() {
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        flowLayout.itemSize = mode.itemSize
        flowLayout.minimumInteritemSpacing = mode.minimumInteritemSpacing
        flowLayout.minimumLineSpacing = mode.minimumLineSpacing
        flowLayout.sectionInset = mode.sectionInset
    }
    
}

extension AppPageCell: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = items[indexPath.item]
        switch item {
        case .app(let app):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.app, for: indexPath)!
            cell.app = app
            if isEditing {
                cell.startShaking()
            } else {
                cell.stopShaking()
            }
            if let draggedItem = draggedItem, draggedItem == .app(app) {
                cell.contentView.isHidden = true
            } else {
                cell.contentView.isHidden = false
            }
            cell.label?.isHidden = mode == .pinned
            return cell
        case .folder(let folder):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.app_folder, for: indexPath)!
            cell.folder = folder
            if isEditing {
                cell.startShaking()
                cell.moveToFirstAvailablePage(animated: false)
            } else {
                cell.stopShaking()
                cell.leaveEditingMode()
            }
            if let draggedItem = draggedItem, draggedItem == .folder(folder) {
                cell.contentView.isHidden = true
            } else {
                cell.contentView.isHidden = false
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? HomeAppCell else {
            return
        }
        delegate?.appPageCell(self, didSelect: cell)
    }
    
}
