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
    @IBOutlet weak var oaButtonRequestCheckBox: NSButton!
    @IBOutlet weak var coreRecomCheckBox: NSButton!
    @IBOutlet weak var openCitationsCheckBox: NSButton!
    @IBOutlet weak var noConsoleLogCheckBox: NSButton!
    @IBOutlet weak var illRequestCheckBox: NSButton!
    @IBOutlet weak var searchEngineSelect: NSPopUpButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        if(!preferences.isSetup()){
            preferences.doSetup()
        }
    }
    
    override func viewWillAppear() {
        setAllCheckBoxes()
        setSearchEngine()
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
        
        let oaButtonRequest = preferences.getValue(key: "oabrequest")
        if(oaButtonRequest){
            oaButtonRequestCheckBox.state = .on
        }
        else{
            oaButtonRequestCheckBox.state = .off
        }
        
        let illRequest = preferences.getValue(key: "ill")
        if(illRequest){
            illRequestCheckBox.state = .on
        }
        else{
            illRequestCheckBox.state = .off
        }
        
        let coreRecom = preferences.getValue(key: "corerecom")
        if(coreRecom){
            coreRecomCheckBox.state = .on
        }
        else{
            coreRecomCheckBox.state = .off
        }
        
        let openCitations = preferences.getValue(key: "opencitations")
        if(openCitations){
            openCitationsCheckBox.state = .on
        }
        else{
            openCitationsCheckBox.state = .off
        }
        
        let noConsoleLog = preferences.getValue(key: "noconsolelog")
        if(noConsoleLog){
            noConsoleLogCheckBox.state = .on
        }
        else{
            noConsoleLogCheckBox.state = .off
        }

    }
    
    func setSearchEngine() {
        let searchEngineTag = preferences.getIntVal(key: "searchengine")
        let searchEngineIndex = searchEngineSelect.indexOfItem(withTag: searchEngineTag)
        searchEngineSelect.itemArray[0].state = .off
        searchEngineSelect.itemArray[searchEngineIndex].state = .on
        searchEngineSelect.select(searchEngineSelect.itemArray[searchEngineIndex])
    }
    
    @IBAction func coreClicked(_ sender: NSButton) {
        if(sender.state == .on){
            preferences.setValue(key: "core", value: true)
        }
        else{
            preferences.setValue(key: "core", value: false)
        }
    }
    
    
    @IBAction func illRequestClicked(_ sender: NSButton) {
        if(sender.state == .on){
            preferences.setValue(key: "ill", value: true)
        }
        else{
            preferences.setValue(key: "ill", value: false)
        }
    }
    
    
    @IBAction func oaButtonRequestClicked(_ sender: NSButton) {
        if(sender.state == .on){
            preferences.setValue(key: "oabrequest", value: true)
        }
        else{
            preferences.setValue(key: "oabrequest", value: false)
        }
    }
    
    @IBAction func coreRecomClicked(_ sender: NSButton) {
        if(sender.state == .on){
            preferences.setValue(key: "corerecom", value: true)
        }
        else{
            preferences.setValue(key: "corerecom", value: false)
        }
    }
    
    @IBAction func openCitationsClicked(_ sender: NSButton) {
        if(sender.state == .on){
            preferences.setValue(key: "opencitations", value: true)
        }
        else{
            preferences.setValue(key: "opencitations", value: false)
        }
    }
    
    @IBAction func noConsoleLogClicked(_ sender: NSButton) {
        if(sender.state == .on){
            preferences.setValue(key: "noconsolelog", value: true)
        }
        else{
            preferences.setValue(key: "noconsolelog", value: false)
        }
    }
    
    
    @IBAction func selectSearchEngineChange(_ sender: NSPopUpButton) {
        if let tag = sender.selectedItem?.tag {
            preferences.setIntVal(key: "searchengine", value: tag)
        }
    }
    

    

    
    
    
    
    @IBAction func tellMeMoreClicked(_ sender: Any) {
        if let url = URL(string: "https://www.oahelper.org/help-settings/"),
            NSWorkspace.shared.open(url) {
        }
    }
    
    @IBAction func noneSelected(_ sender: Any){
        coreCheckBox.state = .off
        oaButtonRequestCheckBox.state = .off
        openCitationsCheckBox.state = .off
        noConsoleLogCheckBox.state = .off
        illRequestCheckBox.state = .off
        coreRecomCheckBox.state = .off
        preferences.setValue(key: "core", value: false)
        preferences.setValue(key: "oabutton", value: false)
        preferences.setValue(key: "oabrequest", value: false)
        preferences.setValue(key: "opencitations", value: false)
        preferences.setValue(key: "noconsolelog", value: false)
        preferences.setValue(key: "corerecom", value: false)
        preferences.setValue(key: "ill", value: false)
    }
    
    @IBAction func recommendedSelected(_ sender: Any){
        coreCheckBox.state = .on
        oaButtonRequestCheckBox.state = .on
        openCitationsCheckBox.state = .on
        noConsoleLogCheckBox.state = .on
        preferences.setValue(key: "core", value: true)
        preferences.setValue(key: "oabutton", value: false)
        preferences.setValue(key: "oabrequest", value: true)
        preferences.setValue(key: "opencitations", value: true)
        preferences.setValue(key: "noconsolelog", value: true)
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
            let settingsTitle = NSLocalizedString("Settings: ", comment: "touchbar label")
            customViewItem.view = NSTextField(labelWithString: settingsTitle)
            return customViewItem
        case NSTouchBarItem.Identifier.moreInfo:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let buttonTitle = NSLocalizedString("Tell me more...", comment: "touchbar button")
            let button = NSButton(title: buttonTitle, target: self, action: #selector(tellMeMoreClicked(_:)))
            saveItem.view = button
            return saveItem
        case NSTouchBarItem.Identifier.noneSelected:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let buttonTitle = NSLocalizedString("Deselect All", comment: "touchbar button")
            let button = NSButton(title: buttonTitle, target: self, action: #selector(noneSelected(_:)))
            button.bezelColor = NSColor.systemOrange
            saveItem.view = button
            return saveItem
        case NSTouchBarItem.Identifier.recommendedSelected:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let buttonTitle = NSLocalizedString("Recommended Settings", comment: "touchbar button")
            let button = NSButton(title: buttonTitle, target: self, action: #selector(recommendedSelected(_:)))
            button.bezelColor = NSColor.systemBlue
            saveItem.view = button
            return saveItem
        default:
            return nil
        }
    }
}
