//
//  StatisticsController.swift
//  Open Access Helper
//
//  Created by Claus Wolf on 31.01.20.
//  Copyright © 2020 Claus Wolf. All rights reserved.
//

import Cocoa

class StatisticsController: NSViewController {
    
    @IBOutlet weak var oaFoundCountExplanationLabel: NSTextField!
    @IBOutlet weak var oaSearchCountExplanationLabel: NSTextField!
    @IBOutlet weak var ezProxyCountExplanationLabel: NSTextField!
    
    @IBOutlet weak var oaFoundCountLabel: NSTextField!
    @IBOutlet weak var oaSearchCountLabel: NSTextField!
    @IBOutlet weak var ezProxyCountLabel: NSTextField!
    
    @IBOutlet weak var shareStats: NSButton!
    
    let preferences = Preferences()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        updateCount()
    }
    
    deinit {
        self.view.window?.unbind(NSBindingName(rawValue: #keyPath(touchBar)))
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        updateCount()
        if #available(OSX 10.12.1, *) {
            self.view.window?.unbind(NSBindingName(rawValue: #keyPath(touchBar))) // unbind first
            self.view.window?.bind(NSBindingName(rawValue: #keyPath(touchBar)), to: self, withKeyPath: #keyPath(touchBar), options: nil)
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        if #available(OSX 10.12.1, *) {
            self.view.window?.unbind(NSBindingName(rawValue: #keyPath(touchBar))) // unbind first
            self.view.window?.bind(NSBindingName(rawValue: #keyPath(touchBar)), to: self, withKeyPath: #keyPath(touchBar), options: nil)
        }
    }
    
    func updateCount(){
        let oaFoundCount = preferences.getIntVal(key: "oaFoundCount")
        let oaSearchCount = preferences.getIntVal(key: "oaSearchCount")
        let ezProxyCount = preferences.getIntVal(key: "ezProxyCount")
        
        oaFoundCountLabel.stringValue = "\(oaFoundCount)"
        oaSearchCountLabel.stringValue = "\(oaSearchCount)"
        
        let proxyPrefix = preferences.getStringValue(key: "ezproxyPrefix")
        
        if(proxyPrefix == ""){
            ezProxyCountExplanationLabel.stringValue = NSLocalizedString("You did not setup Proxy Support yet", comment: "shown in stats, if no proxy prefix present")
            ezProxyCountLabel.isHidden = true
        }
        else{
            ezProxyCountLabel.stringValue = "\(ezProxyCount)"
        }
        
    }
    
    
    
    @IBAction func privacyPolicyClicked(_ sender: Any) {
        if let url = URL(string: "https://www.oahelper.org/privacy-policy/"),
            NSWorkspace.shared.open(url) {
        }
    }
    
    @IBAction func tellMeMoreClicked(_ sender: Any) {
        if let url = URL(string: "https://www.oahelper.org/2020/06/07/macos-what-statistics-do-you-collect/"),
            NSWorkspace.shared.open(url) {
        }
    }
    
    
}

@available(OSX 10.12.1, *)
extension StatisticsController: NSTouchBarDelegate {
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .bar6
        touchBar.defaultItemIdentifiers = [.label7, .privacyPolicy, .privacyTellMeMore]
        touchBar.customizationAllowedItemIdentifiers = [.label7, .privacyPolicy, .privacyTellMeMore]
        return touchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItem.Identifier.label7:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            let customViewItemLabel = NSLocalizedString("Basic Usage Statistics", comment: "")
            customViewItem.view = NSTextField(labelWithString: customViewItemLabel)
            return customViewItem
        case NSTouchBarItem.Identifier.privacyPolicy:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "Privacy Policy", target: self, action: #selector(privacyPolicyClicked(_:)))
            saveItem.view = button
            return saveItem
        case NSTouchBarItem.Identifier.privacyTellMeMore:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "Tell me more...", target: self, action: #selector(tellMeMoreClicked(_:)))
            saveItem.view = button
            return saveItem
        default:
            return nil
        }
    }
}
