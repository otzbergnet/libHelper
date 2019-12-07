//
//  SettingsController.swift
//  Open Access Helper
//
//  Created by Claus Wolf on 11.08.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Cocoa

class SettingsController: NSViewController {
    
    let preferences = Preferences()
    
    @IBOutlet weak var coreCheckBox: NSButton!
    @IBOutlet weak var oaButtonCheckBox: NSButton!
    @IBOutlet weak var oaButtonRequestCheckBox: NSButton!
    @IBOutlet weak var basesearchHSCheckBox: NSButton!
    @IBOutlet weak var coreHSCheckBox: NSButton!
    @IBOutlet weak var gettheresearchHSCheckBox: NSButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        if(!preferences.isSetup()){
            preferences.doSetup()
        }
        setAllCheckBoxes()
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
    
    func setAllCheckBoxes(){
        let core = preferences.getValue(key: "core")
        if(core){
            coreCheckBox.state = .on
        }
        else{
            coreCheckBox.state = .off
        }
        let oaButton = preferences.getValue(key: "oabutton")
        if(oaButton){
            oaButtonCheckBox.state = .on
        }
        else{
            oaButtonCheckBox.state = .off
        }
        let oaButtonRequest = preferences.getValue(key: "oabrequest")
        if(oaButtonRequest){
            oaButtonRequestCheckBox.state = .on
        }
        else{
            oaButtonRequestCheckBox.state = .off
        }
        
        let baseHS = preferences.getValue(key: "basehs")
        if(baseHS){
            basesearchHSCheckBox.state = .on
        }
        else{
            basesearchHSCheckBox.state = .off
        }
        
        let coreHS = preferences.getValue(key: "corehs")
        if(coreHS){
            coreHSCheckBox.state = .on
        }
        else{
            coreHSCheckBox.state = .off
        }
        
        let gettheresearchHS = preferences.getValue(key: "gettheresearchhs")
        if(gettheresearchHS){
            gettheresearchHSCheckBox.state = .on
        }
        else{
            gettheresearchHSCheckBox.state = .off
        }
    }
    
    @IBAction func coreClicked(_ sender: Any) {
        let state = coreCheckBox.state
        if(state == .on){
            preferences.setValue(key: "core", value: true)
        }
        else{
            preferences.setValue(key: "core", value: false)
        }
    }
    
    
    @IBAction func oaButtonClicked(_ sender: Any) {
        let state = oaButtonCheckBox.state
        if(state == .on){
            preferences.setValue(key: "oabutton", value: true)
        }
        else{
            preferences.setValue(key: "oabutton", value: false)
        }
    }
    
    @IBAction func oaButtonRequestClicked(_ sender: Any) {
        let state = oaButtonRequestCheckBox.state
        if(state == .on){
            preferences.setValue(key: "oabrequest", value: true)
        }
        else{
            preferences.setValue(key: "oabrequest", value: false)
        }
    }
    
    @IBAction func basesearchHSclicked(_ sender: Any) {
        let state = basesearchHSCheckBox.state
        if(state == .on){
            preferences.setValue(key: "basehs", value: true)
        }
        else{
            preferences.setValue(key: "basehs", value: false)
        }
    }
    
    @IBAction func coreHSclicked(_ sender: Any) {
        let state = coreHSCheckBox.state
        if(state == .on){
            preferences.setValue(key: "corehs", value: true)
        }
        else{
            preferences.setValue(key: "corehs", value: false)
        }
    }
    
    @IBAction func gettheresearchHSclicked(_ sender: Any) {
        let state = gettheresearchHSCheckBox.state
        if(state == .on){
            preferences.setValue(key: "gettheresearchhs", value: true)
        }
        else{
            preferences.setValue(key: "gettheresearchhs", value: false)
        }
    }
    
    
    
    @IBAction func tellMeMoreClicked(_ sender: Any) {
        if let url = URL(string: "https://www.otzberg.net/oahelper/settings.html"),
            NSWorkspace.shared.open(url) {
        }
    }
    
    @IBAction func noneSelected(_ sender: Any){
        coreCheckBox.state = .off
        oaButtonCheckBox.state = .off
        oaButtonRequestCheckBox.state = .off
        preferences.setValue(key: "core", value: false)
        preferences.setValue(key: "oabutton", value: false)
        preferences.setValue(key: "oabrequest", value: false)
    }
    
    @IBAction func recommendedSelected(_ sender: Any){
        coreCheckBox.state = .on
        oaButtonCheckBox.state = .off
        oaButtonRequestCheckBox.state = .on
        preferences.setValue(key: "core", value: true)
        preferences.setValue(key: "oabutton", value: false)
        preferences.setValue(key: "oabrequest", value: true)
    }
    
}

@available(OSX 10.12.1, *)
extension SettingsController: NSTouchBarDelegate {
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .bar3
        touchBar.defaultItemIdentifiers = [.label3, .noneSelected, .recommendedSelected, .moreInfo]
        touchBar.customizationAllowedItemIdentifiers = [.label3, .noneSelected, .recommendedSelected, .moreInfo]
        return touchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItem.Identifier.label3:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            customViewItem.view = NSTextField(labelWithString: "Settings: ")
            return customViewItem
        case NSTouchBarItem.Identifier.moreInfo:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "Tell me more...", target: self, action: #selector(tellMeMoreClicked(_:)))
            saveItem.view = button
            return saveItem
        case NSTouchBarItem.Identifier.noneSelected:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "Deselect All", target: self, action: #selector(noneSelected(_:)))
            button.bezelColor = NSColor.systemOrange
            saveItem.view = button
            return saveItem
        case NSTouchBarItem.Identifier.recommendedSelected:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: "Recommended Settings", target: self, action: #selector(recommendedSelected(_:)))
            button.bezelColor = NSColor.systemBlue
            saveItem.view = button
            return saveItem
        default:
            return nil
        }
    }
}
