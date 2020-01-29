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
    
    @IBOutlet weak var proxyPrefixTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    
    @IBAction func saveClicked(_ sender: Any) {
        
    }
    
}
