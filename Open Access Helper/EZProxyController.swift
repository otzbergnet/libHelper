//
//  EZProxyController.swift
//  Open Access Helper
//
//  Created by Claus Wolf on 29.01.20.
//  Copyright © 2020 Claus Wolf. All rights reserved.
//

import Cocoa

class EZProxyController: NSViewController {

    let preferences = Preferences()
    
    @IBOutlet weak var testSettingsButton: NSButton!
    @IBOutlet weak var proxyPrefixTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showTestSettingsButton()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.showTestSettingsButton()
    }
    
    func showTestSettingsButton(){
        let proxyPrefix = preferences.getStringValue(key: "ezproxyPrefix") // always returns at least an empty String
        //print(proxyPrefix)
        if (proxyPrefix != "" && validateProxyPrefix(urlString: proxyPrefix)){
            self.testSettingsButton.isHidden = false
            self.proxyPrefixTextField.stringValue = "\(proxyPrefix)"
        }
        else{
            self.testSettingsButton.isHidden = true
        }
        
    }
    
    func validateProxyPrefix(urlString: String) -> Bool {
        if(urlString == ""){
            self.preferences.setStringValue(key: "ezproxyPrefix", value: "")
            return false
        }
        
        let prefix = urlString.prefix(4)
        let suffix = urlString.suffix(5)
        let testService = "https://www.jstor.org"
        let testUrl = urlString+testService
        
        if(prefix != "http"){
            return false
        }
        if(suffix != "?url=" && suffix != "qurl=" && suffix != "&url="){
            return false
        }
        
        
        if let url = URL(string: testUrl) {
            let urlRequest = URLRequest.init(url: url)
            return NSURLConnection.canHandle(urlRequest)
        }
        return false
    }
    
    
    @IBAction func saveClicked(_ sender: Any) {
        let url = self.proxyPrefixTextField.stringValue
        if(self.validateProxyPrefix(urlString: url)){
            self.preferences.setStringValue(key: "ezproxyPrefix", value: url)
            self.showTestSettingsButton()
        }
        else{
            print("invalid prefix")
        }
    }
    
    @IBAction func testClicked(_ sender: Any) {
        let proxyPrefix = preferences.getStringValue(key: "ezproxyPrefix")
        let testService = "https://www.jstor.org"
        let testUrl = proxyPrefix+testService
        if let url = URL(string: testUrl),
            NSWorkspace.shared.open(url) {
        }
    }
    
    
}
