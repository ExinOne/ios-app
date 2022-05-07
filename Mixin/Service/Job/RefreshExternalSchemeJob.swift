import Foundation
import MixinServices

class RefreshExternalSchemeJob: AsynchronousJob {
    
    override func getJobId() -> String {
        "refresh-external-scheme"
    }
    
    override func execute() -> Bool {
        ExternalSchemeAPI.schemes { result in
            switch result {
            case let .success(schemes):
                AppGroupUserDefaults.User.externalSchemes = schemes
                AppGroupUserDefaults.User.externalSchemesRefreshDate = Date()
            case .failure:
                break
            }
            self.finishJob()
        }
        return true
    }
    
}
