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
    
    func readSettings() -> String{
        let file = "count.txt" //this is the file. we will write to and read from it
        
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
        updateCount()
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func updateCount(){
        let count = readSettings()
        oaCount.stringValue = "OA found: \(count)"
    }
    
    
    
}
