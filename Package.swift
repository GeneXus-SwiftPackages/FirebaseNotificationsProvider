// swift-tools-version: 5.9
import PackageDescription
import Foundation

let GX_FC_LAST_VERSION = Version("5.0.0-beta")

let package = Package(
	name: "FirebaseNotificationsProvider",
	platforms: [.iOS(.v15)],
	products: [
		.library(name: "FirebaseNotificationProvider", targets: ["FirebaseNotificationProvider"]),
		.library(name: "FirebaseNotificationServiceExtension", targets: ["FirebaseNotificationServiceExtension"]),
	],
	dependencies: [
		.gxFramework("GXCoreBL"),
		.gxFramework("GXCoreModule_SD_Notifications"),
		.package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "12.3.0"))
	],
	targets: [
		.target(name: "FirebaseNotificationProvider",
				dependencies: [
					.product(name: "GXCoreBL", package: "GXCoreBL"),
					.product(name: "GXCoreModule_SD_Notifications", package: "GXCoreModule_SD_Notifications"),
					.product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
				],
				path: "Sources/NotificationsProvider"),
		.target(name: "FirebaseNotificationServiceExtension",
				dependencies: [
					.product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
				],
				path: "Sources/NotificationsServiceExtension"),
	]
)

// MARK: - Flexible Client dependencies (public binaries by default, local packages when GX_FRAMEWORKS_LOCAL_PATH is set)
// Same mechanism used by GeneXus-SwiftPackages/GXGoogleMaps. See iOSFlexibleClient/docs/gpn.md.

extension Package.Dependency {
	static func gxFramework(_ name: String) -> Package.Dependency {
		guard let localPath = gxFrameworksLocalPath() else {
			return .package(url: "https://github.com/GeneXus-SwiftPackages/\(name).git", .upToNextMajor(from: GX_FC_LAST_VERSION))
		}
		return .package(name: name, path: localPath.appending(component: name).path)
	}
}

func gxFrameworksLocalPath() -> URL? {
	guard let pathCString = getenv("GX_FRAMEWORKS_LOCAL_PATH") else {
		return nil
	}
	let path = String(cString: pathCString)
	return URL(filePath: path)
}
