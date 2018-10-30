//
//  ViewController.swift
//  libHelper
//
//  Created by Claus Wolf on 28.10.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var proxyUpdateField: NSTextField!
    
    func writeSettings( theSetting: String ) {
        let file = "ezproxy.text" //this is the file. we will write to and read from it
        
        let text = theSetting //just a text
        
        let fileManager = FileManager.default
        guard let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "net.otzberg.shared") else {
            return
        }
        let safariExtDir = groupURL.appendingPathComponent("Library/Caches/")
        let fileURL = safariExtDir.appendingPathComponent(file)
        
        //writing
        do {
            try text.write(to: fileURL, atomically: false, encoding: .utf8)
        }
        catch {/* error handling here */}
        
        
    }
    
    func readSettings() -> String{
        let file = "ezproxy.text" //this is the file. we will write to and read from it
        
        var text2 = ""
        
        let fileManager = FileManager.default
        guard let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "net.otzberg.shared") else {
            return ""
        }
        let safariExtDir = groupURL.appendingPathComponent("Library/Caches/")
        let fileURL = safariExtDir.appendingPathComponent(file)
        
        //reading
        do {
            text2 = try String(contentsOf: fileURL, encoding: .utf8)
        }
        catch {
            text2 = "ezproxy.avans.nl"
        }
        
        
        return text2
    }
    
    @IBAction func updateProxyClicked(_ sender: Any) {
        NSLog("I have been asked to set the proxy URL to: " + proxyUpdateField.stringValue)
        
        writeSettings(theSetting: proxyUpdateField.stringValue)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        proxyUpdateField.stringValue = readSettings()
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
    
}
