import SwiftUI
extension SparkleUpdater { public struct DownloadingView: View { public init(cancel: @escaping () -> Void, downloadStartTimestamp: Date, latestVersionString: String, totalSizeInBytes: Int64, progress: Double, statusString: String) {}; public var body: some View { EmptyView() } } }
