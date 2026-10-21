//
//  GXNotificationsProvider_FirebaseExtensionLibrary.swift
//  GXNotificationsProvider_Firebase
//

import GXCoreBL

@objc(GXNotificationsProvider_FirebaseExtensionLibrary)
public class GXNotificationsProvider_FirebaseExtensionLibrary: NSObject, GXExtensionLibraryProtocol {

	public func initializeExtensionLibrary(withContext context: GXExtensionLibraryContext) {
		GXUserNotificationsManager.registerNotificationsProviderClass(GXUserNotificationsProviderFirebase.self,
																	   forTypeIdentifier: GXUserNotificationsProviderFirebase.notificationsProviderTypeIdentifier)
	}
}
