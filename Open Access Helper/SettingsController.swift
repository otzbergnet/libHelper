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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        if(!preferences.isSetup()){
            preferences.doSetup()
        }
        setAllCheckBoxes()
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
    
    @IBAction func tellMeMoreClicked(_ sender: Any) {
        if let url = URL(string: "https://www.otzberg.net/oahelper/settings.html"),
            NSWorkspace.shared.open(url) {
        }
    }
    
}
