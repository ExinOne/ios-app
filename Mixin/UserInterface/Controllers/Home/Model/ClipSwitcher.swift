import UIKit
import WebKit
import MixinServices

class ClipSwitcher {
    
    static let maxNumber = 6
    
    private(set) var clips: [Clip] = []
    private(set) weak var fullscreenSwitcherIfLoaded: ClipSwitcherViewController?
    
    private lazy var fullscreenSwitcher: ClipSwitcherViewController = {
        let controller = R.storyboard.home.clip_switcher()!
        self.fullscreenSwitcherIfLoaded = controller
        return controller
    }()
    
    private var minimizedController: MinimizedClipSwitcherViewController? {
        let container = UIApplication.homeContainerViewController
        return container?.minimizedClipSwitcherViewController
    }
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveMemoryWarningNotification(_:)),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadClipsFromPreviousSession() {
        clips = AppGroupUserDefaults.User.clips.compactMap { (data) -> Clip? in
            try? JSONDecoder.default.decode(Clip.self, from: data)
        }
        if let controller = minimizedController {
            controller.replaceClips(with: clips)
            controller.panningController.placeViewNextToLastOverlayOrTopRight()
        }
    }
    
    func appendClip(with controller: MixinWebViewController) {
        guard !clips.contains(where: { $0.controllerIfLoaded == controller }) else {
            return
        }
        let clip: Clip
        switch controller.context.style {
        case let .app(app, _):
            clip = Clip(app: app,
                        url: controller.webView.url ?? URL(string: app.homeUri) ?? .blank,
                        controller: controller)
        case .webPage:
            clip = Clip(app: nil,
                        url: controller.webView.url ?? .blank,
                        controller: controller)
        }
        minimizedController?.appendClip(clip)
        clips.append(clip)
        
        let config = WKSnapshotConfiguration()
        config.rect = controller.webView.frame
        config.snapshotWidth = NSNumber(value: Int(controller.webView.frame.width))
        controller.webView.takeSnapshot(with: config) { (image, error) in
            clip.thumbnail = image
        }
        
        AppGroupUserDefaults.User.clips = clips.compactMap { (clip) -> Data? in
            try? JSONEncoder.default.encode(clip)
        }
    }
    
    func removeClip(at index: Int) {
        minimizedController?.removeClip(at: index)
        clips.remove(at: index)
        if index < AppGroupUserDefaults.User.clips.count {
            AppGroupUserDefaults.User.clips.remove(at: index)
        }
    }
    
    func replaceClips(with clips: [Clip]) {
        minimizedController?.replaceClips(with: [])
        self.clips = clips
        AppGroupUserDefaults.User.clips = clips.compactMap { (clip) -> Data? in
            try? JSONEncoder.default.encode(clip)
        }
    }
    
    func hideFullscreenSwitcher() {
        fullscreenSwitcher.hide()
    }
    
    @objc func showFullscreenSwitcher() {
        fullscreenSwitcher.clips = clips
        fullscreenSwitcher.show()
    }
    
    @objc func didReceiveMemoryWarningNotification(_ notification: Notification) {
        for clip in clips {
            clip.removeCachedController()
        }
    }
    
}
