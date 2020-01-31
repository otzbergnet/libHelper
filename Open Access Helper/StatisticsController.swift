//
//  StatisticsController.swift
//  Open Access Helper
//
//  Created by Claus Wolf on 31.01.20.
//  Copyright © 2020 Claus Wolf. All rights reserved.
//

import Cocoa

class StatisticsController: NSViewController {
    
    @IBOutlet weak var oaCount: NSTextField!
    @IBOutlet weak var oaSearchCountLabel: NSTextField!
    
    
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
        let count = preferences.getIntVal(key: "oaFoundCount")
        let myOASearchCount = preferences.getIntVal(key: "oaSearchCount")
        oaCount.stringValue = String(format: NSLocalizedString("So far we've helped you find %@ Open Access Documents!", comment: "shows on main window, number of OpenAccess found"), "\(count)")
        
        oaSearchCountLabel.stringValue = String(format: NSLocalizedString("You've had help with %@ Open Access searches", comment: "shows on main window, number of OpenAccess Searches conducted"), "\(myOASearchCount)")
        
    }
    

    
}
