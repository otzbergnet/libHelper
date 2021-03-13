//
//  HelpViewController.swift
//  Open Access Helper
//
//  Created by Claus Wolf on 10.11.18.
//  Copyright © 2018-2021 Claus Wolf. All rights reserved.
//

import Cocoa

class HelpViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillAppear() {       
        self.view.window?.styleMask.remove(.fullScreen)
        self.view.window?.styleMask.remove(.resizable)
    }
    
    @IBAction func onlineHelpClicked(_ sender: Any) {
        if let url = URL(string: "https://www.oahelper.org/"),
            NSWorkspace.shared.open(url) {
            self.dismiss(self)
        }
    }
    
    @IBAction func closeClicked(_ sender: Any) {
        self.dismiss(self)
    }
    
    
}

class HelpMenuItems: NSMenuItem{
    
    
    
}
