//
//  ViewController.swift
//  libHelper
//
//  Created by Claus Wolf on 28.10.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import Cocoa
import SafariServices.SFSafariApplication

class ViewController: NSViewController {
    
    let preferences = Preferences()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(!preferences.isSetup()){
            preferences.doSetup()
        }
    }
    
    deinit {
        self.view.window?.unbind(NSBindingName(rawValue: #keyPath(touchBar)))
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if #available(OSX 10.12.1, *) {
            self.view.window?.unbind(NSBindingName(rawValue: #keyPath(touchBar))) // unbind first
            self.view.window?.bind(NSBindingName(rawValue: #keyPath(touchBar)), to: self, withKeyPath: #keyPath(touchBar), options: nil)
        }
    }
    
    override func viewWillAppear() {
        
        self.view.window?.styleMask.remove(.fullScreen)
        self.view.window?.styleMask.remove(.resizable)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
    
    @IBAction func openSafariPreferences(_ sender: Any) {
        openSafariPreferencesNow()
    }
    
    @IBAction func exampleTapped(_ sender: Any) {
        showMyExample()
    }
    
   func openSafariPreferencesNow(){
        SFSafariApplication.showPreferencesForExtension(withIdentifier: "net.otzberg.libHelper.libHelper-Safari") { error in
            if let _ = error {
                // Insert code to inform the user that something went wrong.
            }
        }
    }
    
    func showMyExample(){
        if let url = URL(string: "https://www.oahelper.org/example.html"),
            NSWorkspace.shared.open(url) {
        }
    }
    
}

@available(OSX 10.12.1, *)
extension ViewController: NSTouchBarDelegate {
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .bar1
        touchBar.defaultItemIdentifiers = [.label1, .openPreferences, .openExample]
        touchBar.customizationAllowedItemIdentifiers = [.label1, .openPreferences, .openExample]
        return touchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItem.Identifier.label1:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            let labelString = NSLocalizedString("Getting Started: ", comment: "")
            customViewItem.view = NSTextField(labelWithString: labelString)
            return customViewItem
        case NSTouchBarItem.Identifier.openPreferences:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let labelString = NSLocalizedString("Open Safari Preferences", comment: "")
            let button = NSButton(title: labelString, target: self, action: #selector(openSafariPreferences(_:)))
            saveItem.view = button
            return saveItem
        case NSTouchBarItem.Identifier.openExample:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let labelString = NSLocalizedString("Show Example", comment: "")
            let button = NSButton(title: labelString, target: self, action: #selector(exampleTapped(_:)))
            saveItem.view = button
            return saveItem
        default:
            return nil
        }
    }
}
