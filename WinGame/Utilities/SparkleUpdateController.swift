import Foundation
import Combine
public enum DummyUpdate { case update }
public class SparkleUpdateController: ObservableObject, @unchecked Sendable {
    public static let shared = SparkleUpdateController()
    public enum UpdateState { case checking, downloading, readyToInstall, idle, updateAvailable, readyToRelaunch((DummyUpdate) -> Void) }
    @Published public var state: UpdateState = .idle
    public func checkForUpdates(userInitiated: Bool) {}
}
