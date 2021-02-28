//
//  AppDelegate.swift
//  libHelper
//
//  Created by Claus Wolf on 28.10.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let preferences = Preferences()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if #available(OSX 10.12.1, *) {
          NSApplication.shared.isAutomaticCustomizeTouchBarMenuItemEnabled = true
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // MARK: - URL Scheme Support
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager
            .shared()
            .setEventHandler(
                self,
                andSelector: #selector(handleURL(event:reply:)),
                forEventClass: AEEventClass(kInternetEventClass),
                andEventID: AEEventID(kAEGetURL)
            )

    }

    @objc func handleURL(event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        if let path = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue?.removingPercentEncoding {
            let url = URL(string: "\(path)")!
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            var tabToShow = 2
            if let components = components {
                if let queryItems = components.queryItems {
                    for queryItem in queryItems {
                        if(queryItem.name == "proxy"){
                            tabToShow = 3
                            if let base64data = queryItem.value{
                                if let data = Data(base64Encoded: base64data){
                                    if let urlString = String(data: data, encoding: .utf8){
                                        self.preferences.setStringValue(key: "ezproxyPrefix", value: urlString)
                                    }
                                }
                            }
                        }
                        if(queryItem.name == "ill"){
                            if let base64data = queryItem.value{
                                if let data = Data(base64Encoded: base64data){
                                    if let urlString = String(data: data, encoding: .utf8){
                                        self.preferences.setStringValue(key: "illUrl", value: urlString)
                                    }
                                }
                            }
                        }
                        if(queryItem.name == "id"){
                            if let instituteId = queryItem.value{
                                self.preferences.setStringValue(key: "instituteId", value: instituteId)
                            }
                        }
                        if(queryItem.name == "name"){
                            if let instituteName = queryItem.value{
                                self.preferences.setStringValue(key: "instituteName", value: instituteName)
                            }
                        }
                    }
                }
            }
            let myTabBar = NSApplication.shared.mainWindow?.windowController?.contentViewController?.children[0] as! NSTabViewController
            myTabBar.tabView.selectTabViewItem(at: tabToShow)
            myTabBar.tabView.tabViewItem(at: tabToShow).viewController?.viewWillAppear()
        }
    }

    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "libHelper")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !context.hasChanges {
            return .terminateNow
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool{
        return true
    }

    @IBAction func contactMeClicked(_ sender: Any) {
        if let url = URL(string: "https://www.oahelper.org/support/"),
            NSWorkspace.shared.open(url) {
        }
    }
    @IBAction func onlineHelpClicked(_ sender: Any) {
        if let url = URL(string: "https://www.oahelper.org/user-faq/"),
            NSWorkspace.shared.open(url) {
        }
    }
    @IBAction func releaseNotesClicked(_ sender: Any) {
        if let url = URL(string: "https://www.oahelper.org/category/release-notes-macos/"),
            NSWorkspace.shared.open(url) {
        }
    }
}

