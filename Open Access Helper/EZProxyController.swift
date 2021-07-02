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
    let proxyFind = ProxyFind()
    
    @IBOutlet weak var testSettingsButton: NSButton!
    @IBOutlet weak var proxyPrefixTextField: NSTextField!
    @IBOutlet weak var requestFormUrl: NSTextField!
    
    @IBOutlet weak var searchTypeDropDown: NSPopUpButton!
    @IBOutlet weak var domainTextField: NSTextField!
    
    @IBOutlet weak var searchButton: NSButton!
    
    @IBOutlet weak var searchDomainLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showTestSettingsButton()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    deinit {
        self.view.window?.unbind(NSBindingName(rawValue: #keyPath(touchBar)))
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.setupThisView()
        if #available(OSX 10.12.1, *) {
            self.view.window?.unbind(NSBindingName(rawValue: #keyPath(touchBar))) // unbind first
            self.view.window?.bind(NSBindingName(rawValue: #keyPath(touchBar)), to: self, withKeyPath: #keyPath(touchBar), options: nil)
        }
    }
    
    func setupThisView(){
        self.showTestSettingsButton()
        self.searchDomainLabel.stringValue = NSLocalizedString("Search Settings by Domain (e.g. harvard.edu)", comment: "reset to default translation")
        self.searchDomainLabel.textColor = .black
    }
    
    
    func showTestSettingsButton(){
        let proxyPrefix = preferences.getStringValue(key: "ezproxyPrefix") // always returns at least an empty String
        let illUrl = preferences.getStringValue(key: "illUrl")
        //print(proxyPrefix)
        if (proxyPrefix != "" && validateProxyPrefix(urlString: proxyPrefix)){
            self.testSettingsButton.isHidden = false
            self.proxyPrefixTextField.stringValue = "\(proxyPrefix)"
        }
        else{
            self.proxyPrefixTextField.stringValue = "\(proxyPrefix)"
            self.testSettingsButton.isHidden = true
        }
        self.requestFormUrl.stringValue = "\(illUrl)"
        
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
    
    func getProxyForTextfield(){
        let newProxyPrefix = self.preferences.getStringValue(key: "ezproxyPrefix")
        DispatchQueue.main.async {
            self.proxyPrefixTextField.stringValue = newProxyPrefix
        }
    }
    
    func getIllForTextField(){
        let newProxyPrefix = self.preferences.getStringValue(key: "illUrl")
        DispatchQueue.main.async {
            self.requestFormUrl.stringValue = newProxyPrefix
        }
    }
    
    @IBAction func saveClicked(_ sender: Any) {
        let url = self.proxyPrefixTextField.stringValue
        if(self.validateProxyPrefix(urlString: url)){
            self.preferences.setStringValue(key: "ezproxyPrefix", value: url)
            self.showTestSettingsButton()
        }
        else{
            if(url == ""){
                self.preferences.setStringValue(key: "ezproxyPrefix", value: url)
                self.showTestSettingsButton()
            }
            else{
                self.testSettingsButton.isHidden = true
            }
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
    
    @IBAction func lookupClicked(_ sender: Any) {
        if let url = URL(string: "https://www.oahelper.org/proxy/"),
           NSWorkspace.shared.open(url) {
        }
    }
    
    @IBAction func searchByDomainClicked(_ sender: Any) {
        
        self.searchDomainLabel.stringValue = NSLocalizedString("Searching...", comment: "show searching, when looking up settings")
        guard let searchType = searchTypeDropDown.selectedItem?.title else {
            return
        }
        let domain = domainTextField.stringValue
        if(domain.count > 0){
            proxyFind.askForProxy(domain: domain, searchType: searchType) { (res) in
                switch res{
                case .success(let proxyList):
                    if(proxyList.count == 0){
                        self.updateSearchDomainLabel(stringValue: NSLocalizedString("No match was found", comment: "if 0 hits returned"), textColor: .black)
                    }
                    else if(proxyList.count == 1){
                        self.proxyFind.processProxyList(proxyList: proxyList) { (res1) in
                            switch res1 {
                            case .success(_):
                                DispatchQueue.main.async {
                                    self.getProxyForTextfield()
                                    self.getIllForTextField()
                                }
                                self.updateSearchDomainLabel(stringValue:NSLocalizedString("Successfuly, saved!", comment: "if proxy was successfully saved"), textColor: .blue)
                            case .failure(_):
                                self.updateSearchDomainLabel(stringValue: NSLocalizedString("We found a match, but could not get the prefix", comment: "if unable to actually get to the proxyPrefix"), textColor: .black)
                            }
                        }
                    }
                    else{
                        self.updateSearchDomainLabel(stringValue: NSLocalizedString("Please review your domain-name, as we were unable to find just one match", comment: "if there are more than one result"), textColor: .black)
                        
                    }
                case .failure(let error):
                    self.updateSearchDomainLabel(stringValue: NSLocalizedString("We encountered an unexpected error", comment: "if failure received"), textColor: .black)
                    print(error)
                }
            }
        }
        else{
            self.updateSearchDomainLabel(stringValue: NSLocalizedString("Looks like the domain field was empty", comment: "if proxy field was empty"), textColor: .black)
        }
    }
    
    
    
    func updateSearchDomainLabel(stringValue: String, textColor: NSColor) {
        DispatchQueue.main.async {
            self.searchDomainLabel.stringValue = stringValue
            self.searchDomainLabel.textColor = textColor
        }
    }
    
    
    
}

@available(OSX 10.12.1, *)
extension EZProxyController: NSTouchBarDelegate {
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .bar5
        touchBar.defaultItemIdentifiers = [.label6, .saveProxy, .lookupProxy, .testProxy]
        touchBar.customizationAllowedItemIdentifiers = [.label6, .saveProxy, .lookupProxy, .testProxy]
        return touchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItem.Identifier.label6:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            let customViewItemLabel = NSLocalizedString("EZProxy: ", comment: "")
            customViewItem.view = NSTextField(labelWithString: customViewItemLabel)
            return customViewItem
        case NSTouchBarItem.Identifier.saveProxy:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let buttonTitle = NSLocalizedString("Save", comment: "")
            let button = NSButton(title: buttonTitle, target: self, action: #selector(saveClicked(_:)))
            saveItem.view = button
            return saveItem
        case NSTouchBarItem.Identifier.lookupProxy:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let buttonTitle = NSLocalizedString("Lookup", comment: "")
            let button = NSButton(title: buttonTitle, target: self, action: #selector(lookupClicked(_:)))
            saveItem.view = button
            return saveItem
        case NSTouchBarItem.Identifier.testProxy:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let buttonTitle = NSLocalizedString("Test", comment: "")
            let button = NSButton(title: buttonTitle, target: self, action: #selector(testClicked(_:)))
            saveItem.view = button
            return saveItem
        default:
            return nil
        }
    }
}
