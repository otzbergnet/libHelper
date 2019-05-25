//
//  ViewController.swift
//  libHelper
//
//  Created by Claus Wolf on 28.10.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var oaCount: NSTextField!
    @IBOutlet weak var oaSearchCountLabel: NSTextField!
    
    @IBOutlet weak var appStoreIcon: NSButton!
    
    
    func readSettings(file: String) -> String{
        let file = file //this is the file. we will write to and read from it
        
        var text2 = ""
        
        let fileManager = FileManager.default
        guard let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "J3PNNM2UXC.otzshare") else {
            return ""
        }
        let safariExtDir = groupURL.appendingPathComponent("Library/Caches/")
        let fileURL = safariExtDir.appendingPathComponent(file)
        
        //reading
        do {
            text2 = try String(contentsOf: fileURL, encoding: .utf8)
        }
        catch {
            text2 = "0"
        }
        
        
        return text2
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeAppStoreBadge()
        updateCount()
    }
    
    override func viewWillAppear() {
        
//        self.view.window?.titleVisibility = .hidden
//        self.view.window?.titlebarAppearsTransparent = true
//
//        self.view.window?.styleMask.insert(.fullSizeContentView)
        self.view.window?.styleMask.remove(.fullScreen)
        //        self.view.window?.styleMask.remove(.miniaturizable)
        self.view.window?.styleMask.remove(.resizable)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func updateCount(){
        let count = readSettings(file: "count.txt")
        let myOASearchCount = readSettings(file: "oacount.txt")
        oaCount.stringValue = String(format: NSLocalizedString("So far we've helped you find %@ Open Access Documents!", comment: "shows on main window, number of OpenAccess found"), count)
        
        oaSearchCountLabel.stringValue = String(format: NSLocalizedString("You've had help with %@ Open Access searches", comment: "shows on main window, number of OpenAccess Searches conducted"), myOASearchCount)
        
    }
    
    func changeAppStoreBadge(){
        if(Locale.current.languageCode == "en"){
            appStoreIcon.image = NSImage(named: "Download_on_the_App_Store_Badge_US")
        }
        else if(Locale.current.languageCode == "de"){
            appStoreIcon.image = NSImage(named: "Download_on_the_App_Store_Badge_DE")
        }
    }
    
    @IBAction func appStoreClicked(_ sender: Any) {
        if let url = URL(string: "https://itunes.apple.com/de/app/open-access-helper/id1447927317?mt=8"),
            NSWorkspace.shared.open(url) {
        }
    }
}
