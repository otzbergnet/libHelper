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
        setShareStatsValue()
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
    
    func setShareStatsValue(){
        let shareStatsValue = self.preferences.getValue(key: "shareStats")
        if(shareStatsValue){
            self.shareStats.state = .on
        }
        else{
            self.shareStats.state = .off
        }
    }
    
    @IBAction func shareStatsClicked(_ sender: NSButton) {
        if(sender.state == .on){
            preferences.setValue(key: "shareStats", value: true)
        }
        else{
            preferences.setValue(key: "shareStats", value: false)
        }
        
    }
    
    
}

@available(OSX 10.12.1, *)
extension StatisticsController: NSTouchBarDelegate {
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .bar6
        touchBar.defaultItemIdentifiers = [.label7]
        touchBar.customizationAllowedItemIdentifiers = [.label7]
        return touchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItem.Identifier.label7:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            let customViewItemLabel = NSLocalizedString("Basic Usage Statistics", comment: "")
            customViewItem.view = NSTextField(labelWithString: customViewItemLabel)
            return customViewItem
        default:
            return nil
        }
    }
}