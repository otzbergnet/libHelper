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
    
    
    let preferences = Preferences()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        updateCount()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        updateCount()
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
    

    
}
