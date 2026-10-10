import os
import glob

os.system("git checkout WinGame/Views/SparkleUpdater")

os.system("git checkout WinGame/WhatsNewCollection.swift")

for file in glob.glob("WinGame/Views/SparkleUpdater/*.swift"):
    name = os.path.basename(file).split('.')[0]
    with open(file, 'w') as f:
        f.write("import SwiftUI\n")
        if name == "SparkleUpdaterSheetViewModifier":
            f.write("public struct SparkleUpdater {}\n")
        elif name == "SparkleUpdaterPreviewView":
            f.write("extension SparkleUpdater { public struct PreviewView: View { public var body: some View { EmptyView() } } }\n")
        elif name == "SparkleUpdaterDownloadingView":
            f.write("extension SparkleUpdater { public struct DownloadingView: View { public init(cancel: @escaping () -> Void, downloadStartTimestamp: Date, latestVersionString: String, totalSizeInBytes: Int64, progress: Double, statusString: String) {}; public var body: some View { EmptyView() } } }\n")
        elif name == "SparkleUpdaterCheckingView":
            f.write("extension SparkleUpdater { public struct CheckingView: View { public init(cancel: @escaping () -> Void) {}; public var body: some View { EmptyView() } } }\n")
        elif name == "SparkleUpdaterFinishView":
            f.write("extension SparkleUpdater { public struct FinishView: View { public init(dismiss: @escaping (Bool) -> Void) {}; public var body: some View { EmptyView() } } }\n")

with open('WinGame/WhatsNewCollection.swift', 'w') as f:
    f.write("""
import SwiftUI

public struct WhatsNewCollection {}
public struct WhatsNewEnvironment {
    public init(versionStore: Any, whatsNewCollection: Any) {}
}

""")
