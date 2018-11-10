//
//  AboutController.swift
//  Open Access Helper
//
//  Created by Claus Wolf on 10.11.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import Cocoa

class AboutController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.window?.titleVisibility = .hidden
        self.view.window?.titlebarAppearsTransparent = true
    }
    
    override func viewWillAppear() {
        self.view.window?.titleVisibility = .hidden
        self.view.window?.titlebarAppearsTransparent = true
        
        self.view.window?.styleMask.insert(.fullSizeContentView)
        self.view.window?.styleMask.remove(.fullScreen)
        self.view.window?.styleMask.remove(.miniaturizable)
        self.view.window?.styleMask.remove(.resizable)
    }
    
    @IBAction func contactMeClicked(_ sender: Any) {
        if let url = URL(string: "https://www.otzberg.net/oahelper#contactme"),
            NSWorkspace.shared.open(url) {
        }
    }
    
    @IBAction func unpaywallClicked(_ sender: Any) {
        if let url = URL(string: "https://unpaywall.org"),
            NSWorkspace.shared.open(url) {
        }
    }
    
    @IBAction func flaticonClicked(_ sender: Any) {
        if let url = URL(string: "https://www.flaticon.com"),
            NSWorkspace.shared.open(url) {
        }
    }
    
    @IBAction func closeClicked(_ sender: Any) {
        self.dismiss(self)
    }
    
}
