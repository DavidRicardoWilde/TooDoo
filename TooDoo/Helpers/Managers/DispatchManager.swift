//
//  DispatchManager.swift
//  TooDoo
//
//  Created by Cali Castle  on 10/14/17.
//  Copyright © 2017 Cali Castle . All rights reserved.
//

import UIKit
import CoreData

/// Manager for Dispatching Operations.

final class DispatchManager {
    
    /// Only instance.
    
    public static let main = DispatchManager()
    
    /// Redirection segue identifier.
    
    open var redirectSegueIdentifier: String?
    
    // MARK: - Application Entry Point
    
    open func applicationLaunched(application: UIApplication, with launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        configureLocale()
        configureAppearance()
        configureRootViewController(for: application)
        configureShortcutItems(for: application, with: launchOptions)
        configureInstallationDateIfNone()
        registerNotifications()
    }
    
    // MARK: - Configure application locale.
    
    fileprivate func configureLocale() {
        let _ = LocaleManager.default
    }
    
    // MARK: - Shortcut Item Trigger Entry Point
    
    open func triggerShortcutItem(shortcutItem: UIApplicationShortcutItem, for application: UIApplication) {
        ShortcutItemManager.triggered(shortcutItem: shortcutItem, for: application)
    }
    
    /// Set redirect to identifier.
    ///
    /// - Parameter notification: Notification event
    
    @objc private func setRedirectTo(_ notification: Notification) {
        guard let identifier = notification.object as? String else { return }
        
        redirectSegueIdentifier = identifier
    }
    
    // MARK: - Core Data Manager Configuration
    
    fileprivate func configureCoreDataManager() -> NSManagedObjectContext {
        // Instanstiate and listen for notifications
        let coreDataManager = CoreDataManager.main
        
        // Create new private context with concurrency
        return coreDataManager.persistentContainer.viewContext
    }
    
    // MARK: - View Controller Configuration
    
    fileprivate func configureRootViewController(for application: UIApplication) {
        guard let appDelegate = application.delegate as? AppDelegate else { return }
        
        // Check to see if user has set up
        guard UserDefaultManager.userHasSetup() else {
            let welcomeViewController = StoryboardManager.initiateViewController(in: .Setup) as! SetupWelcomeViewController
            
            appDelegate.window?.rootViewController = welcomeViewController
            
            // Listen for user setup notification
            NotificationManager.listen(self, do: #selector(userHasSetup), notification: .UserHasSetup, object: nil)
            
            return
        }
        
        guard let navigationController = StoryboardManager.main().instantiateInitialViewController() as? UINavigationController else { return }
        guard let rootViewController = navigationController.topViewController as? ToDoOverviewViewController else { return }
        
        navigationController.viewControllers = [rootViewController]
        
        appDelegate.window?.rootViewController = navigationController
    }
    
    // MARK: - 3D Touch Shortcut Items Configuration
    
    fileprivate func configureShortcutItems(for application: UIApplication, with launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        guard UserDefaultManager.userHasSetup() else { return }
        
        ShortcutItemManager.createItems(for: application)
    }
    
    // MARK: - Appearance Configuration
    
    fileprivate func configureAppearance() {
        AppearanceManager.default.configureAppearances()
    }
    
    /// Once user has finished setup process.
    
    @objc func userHasSetup() {
        // Create shortcut items
        ShortcutItemManager.createItems(for: UIApplication.shared)
        
        // Remove from user setup notification
        NotificationManager.remove(self, notification: .UserHasSetup, object: nil)
    }
    
    /// Configure installation to user defaults if none.
    
    fileprivate func configureInstallationDateIfNone() {
        let _ = UserDefaultManager.userHasBeenUsingThisAppDaysCount()
    }
    
    /// Register notifications for handling.
    
    fileprivate func registerNotifications() {
        NotificationManager.listen(self, do: #selector(setRedirectTo(_:)), notification: .UserAuthenticationRedirect, object: nil)
    }
    
    /// Open app's system settings.
    
    public func openSystemSettings() {
        guard let openSettingsURL = URL(string: UIApplicationOpenSettingsURLString + Bundle.main.bundleIdentifier!) else { return }
        
        if UIApplication.shared.canOpenURL(openSettingsURL) {
            UIApplication.shared.open(openSettingsURL, options: [:], completionHandler: nil)
        }
    }
    
    /// Inaccessible initialization.
    
    private init() {}
}
