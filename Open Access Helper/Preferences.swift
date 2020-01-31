//
//  Preferences.swift
//  Open Access Helper
//
//  Created by Claus Wolf on 11.08.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Cocoa

class Preferences: NSViewController {

    
    
    func isSetup() -> Bool{
        if let defaults = UserDefaults(suiteName: "J3PNNM2UXC.otzshare"){
            if(defaults.bool(forKey: "setup_2020_02")){
                //we are fully setup, nothing needs to happen
                return true
            }
            if(defaults.bool(forKey: "setup_2020_01")){
                //we are partially setup, need to convert stats
                convertOldStatsToNewStats()
                //now set true for current version
                defaults.set(true, forKey: "setup_2020_02")
                return true
            }
            if(defaults.bool(forKey: "setup")){
                //if we got here, it is a old partial setup, need CORE Recom change, need to convert stats
                defaults.set(true, forKey: "corerecom")
                convertOldStatsToNewStats()
                //now set true for current version
                defaults.set(true, forKey: "setup_2020_02")
                //now we can return true, as we are fully setup
                return true
            }
            // if we get here, we need to do a full setup, so we return false
            return false
        }
        else{
            return false
        }
        
    }
    
    func doSetup(){
        if let defaults = UserDefaults(suiteName: "J3PNNM2UXC.otzshare"){
            defaults.set(true, forKey: "setup_2020_02")
            defaults.set(true, forKey: "core")
            defaults.set(false, forKey: "oabutton")
            defaults.set(true, forKey: "oabrequest")
            defaults.set(true, forKey: "corerecom")
            defaults.set(true, forKey: "basehs")
            defaults.set(true, forKey: "corehs")
            defaults.set(false, forKey: "gettheresearchhs")
        }
        
    }
    
    func convertOldStatsToNewStats(){
        print("convert Old Stats")
        if let count = Int(readSettings(file: "count.txt")){
            setIntVal(key: "oaFoundCount", value: count)
        }
        if let myOASearchCount = Int(readSettings(file: "oacount.txt")){
            setIntVal(key: "oaSearchCount", value: myOASearchCount)
        }
    }
    
    
    func getValue(key: String) -> Bool{
        if let defaults = UserDefaults(suiteName: "J3PNNM2UXC.otzshare"){
            return defaults.bool(forKey: key)
        }
        else{
            return false
        }
    }
    
    func setValue(key: String, value: Bool){
        if let defaults = UserDefaults(suiteName: "J3PNNM2UXC.otzshare"){
            defaults.set(value, forKey: key)
        }
    }
    
    func getStringValue(key: String) -> String{
        if let defaults = UserDefaults(suiteName: "J3PNNM2UXC.otzshare"){
            if let stringValue = defaults.string(forKey: key){
                return stringValue
            }
        }
        
        return ""
    }
    
    func setStringValue(key: String, value: String){
        if let defaults = UserDefaults(suiteName: "J3PNNM2UXC.otzshare"){
            defaults.set(value, forKey: key)
        }
    }
    
    func getIntVal(key: String) -> Int{
        if let defaults = UserDefaults(suiteName: "J3PNNM2UXC.otzshare"){
            let intValue = defaults.integer(forKey: key)
            return intValue
        }
        return 0
    }

    func setIntVal(key: String, value: Int){
        if let defaults = UserDefaults(suiteName: "J3PNNM2UXC.otzshare"){
            defaults.set(value, forKey: key)
        }
    }
    
    func incrementIntVal(key: String){
        var intValue = getIntVal(key: key)
        intValue += 1
        setIntVal(key: key, value: intValue)
    }
    
    // MARK: - Old Stats Related Functions
       
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
}
