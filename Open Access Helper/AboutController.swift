//
//  AboutController.swift
//  Open Access Helper
//
//  Created by Claus Wolf on 10.11.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import Cocoa

class AboutController: NSViewController {
    
    @IBOutlet weak var infoText: NSTextField!
    @IBOutlet weak var versionLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        if let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String{
            versionLabel.stringValue = "Version \(appVersion)"
        }
    }
    
    override func viewWillAppear() {
        self.view.window?.styleMask.remove(.fullScreen)
        self.view.window?.styleMask.remove(.resizable)
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
    
    @IBAction func contactMeClicked(_ sender: Any) {
        if let url = URL(string: "https://www.oahelper.org/support/"),
            NSWorkspace.shared.open(url) {
        }
    }
    
    @IBAction func unpaywallClicked(_ sender: Any) {
        if let url = URL(string: "https://unpaywall.org"),
            NSWorkspace.shared.open(url) {
        }
    }
    
    @IBAction func coreClicked(_ sender: Any) {
        if let url = URL(string: "https://www.core.ac.uk"),
            NSWorkspace.shared.open(url) {
        }
    }
    
    @IBAction func oabClicked(_ sender: Any) {
        if let url = URL(string: "https://openaccessbutton.org/"),
            NSWorkspace.shared.open(url) {
        }
    }
    
    
    @IBAction func closeClicked(_ sender: Any) {
        self.dismiss(self)
    }
    
    
}

@available(OSX 10.12.1, *)
extension AboutController: NSTouchBarDelegate {
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .bar2
        touchBar.defaultItemIdentifiers = [.label2, .contact, .unpaywall, .core, .oab]
        touchBar.customizationAllowedItemIdentifiers = [.label2, .contact, .unpaywall, .core, .oab]
        return touchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItem.Identifier.label2:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            let labelString = NSLocalizedString("About: ", comment: "")
            customViewItem.view = NSTextField(labelWithString: labelString)
            return customViewItem
        case NSTouchBarItem.Identifier.contact:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let labelString = NSLocalizedString("Contact Me", comment: "")
            let button = NSButton(title: labelString, target: self, action: #selector(contactMeClicked(_:)))
            saveItem.view = button
            return saveItem
        case NSTouchBarItem.Identifier.unpaywall:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "unpaywall.org", target: self, action: #selector(unpaywallClicked(_:)))
            saveItem.view = button
            return saveItem
        case NSTouchBarItem.Identifier.core:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "core.ac.uk", target: self, action: #selector(coreClicked(_:)))
            saveItem.view = button
            return saveItem
        case NSTouchBarItem.Identifier.oab:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "OpenAccessButton.org", target: self, action: #selector(oabClicked(_:)))
            saveItem.view = button
            return saveItem
        default:
            return nil
        }
    }
}
