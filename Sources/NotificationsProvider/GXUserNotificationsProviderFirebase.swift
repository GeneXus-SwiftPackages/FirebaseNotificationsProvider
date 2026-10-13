//
//  GXUserNotificationsProviderFirebase.swift
//  GXNotificationsProvider_Firebase
//

import Foundation
import UserNotifications
import GXCoreBL
import GXCoreModule_SD_Notifications
import FirebaseCore
import FirebaseMessaging

/// GeneXus notifications provider backed by Firebase Cloud Messaging (FCM).
@objc(GXUserNotificationsProviderFirebase)
open class GXUserNotificationsProviderFirebase: NSObject, GXUserNotificationsProviderProtocol, GXRemoteNotificationsProviderAppDelegateProtocol, MessagingDelegate {

	public static let notificationsProviderTypeIdentifier = "Firebase"

	public static let notificationPlatformIdKey = "NotificationPlatformId"

	private var fcmToken: String? = nil
	private var waitingForTokenCompletions: [([String: Any]) -> Void] = []

	private class func registrationHandlerAdditionalData(withFCMToken token: String?) -> [String: Any] {
		guard let token = token else { return [:] }
		return [notificationPlatformIdKey: token]
	}

	// MARK: - GXUserNotificationsProviderProtocol

	public let typeIdentifier = GXUserNotificationsProviderFirebase.notificationsProviderTypeIdentifier

	open func initializeProvider(withLaunchOptions launchOptions: [AnyHashable: Any]?) -> Void {
		// Another Firebase provider (Analytics, Crashlytics, ...) may already have configured the default app.
		if FirebaseApp.app() == nil {
			FirebaseApp.configure()
		}
		Messaging.messaging().delegate = self
	}

	public final var usesMethodSwizzerlingOnDelegateClasses: Bool { false }

	public final var remoteAppDelegate: any GXRemoteNotificationsProviderAppDelegateProtocol { self }

	// MARK: Remote

	open func registrationHandlerAdditionalData(completion: @escaping ([String: Any]) -> Void) -> Void {
		if let token = self.fcmToken {
			completion(Self.registrationHandlerAdditionalData(withFCMToken: token))
		}
		else {
			// Wait for `messaging(_:didReceiveRegistrationToken:)`.
			waitingForTokenCompletions.append(completion)
		}
	}

	// MARK: - GXRemoteNotificationsProviderAppDelegateProtocol

	public final func onDidRegisterForRemoteNotifications(withDeviceToken devToken: Data) {
		Messaging.messaging().apnsToken = devToken
	}

	public final func onDidFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
		// Nothing provider-specific to do; GeneXus client already handles/logs the failure.
	}

	#if !os(tvOS)
	public final func onDidReceiveRemoteNotification(_ userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping () -> Void) {
		Messaging.messaging().appDidReceiveMessage(userInfo)

		if let notificationActionHandler = GXUNNotificationFactory.actionHandler(for: GXUNNotificationDefaultActionIdentifier, fromPushNotification: userInfo) {
			GXUserNotificationsManager.handleReceivedSilentNotification(notificationActionHandler, withCompletionHandler: completionHandler)
		}
		else {
			completionHandler()
		}
	}
	#endif // !os(tvOS)

	// MARK: - MessagingDelegate

	public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
		let previousToken = self.fcmToken
		self.fcmToken = fcmToken

		guard let fcmToken = fcmToken else { return }

		if !waitingForTokenCompletions.isEmpty {
			// First registration (or a registration waiting for the token): resolve pending completions.
			let completions = waitingForTokenCompletions
			waitingForTokenCompletions.removeAll()
			let additionalData = Self.registrationHandlerAdditionalData(withFCMToken: fcmToken)
			completions.forEach { $0(additionalData) }
		}
		else if let previousToken = previousToken, previousToken != fcmToken, let apnsToken = messaging.apnsToken {
			// Token rotated after the device was already registered: re-run the registration handler
			// so the server stores the new FCM token.
			GXUserNotificationsManager.onDidRegisterForRemoteNotifications(withDeviceToken: apnsToken)
		}
	}
}
