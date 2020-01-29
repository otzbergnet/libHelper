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
            if(defaults.bool(forKey: "setup_2020_01")){
                //we are fully setup, nothing needs to happen
                return true
            }
            if(defaults.bool(forKey: "setup")){
                //if we got here, it is a partial setup, only need CORE Recom change
                defaults.set(true, forKey: "corerecom")
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
            defaults.set(true, forKey: "setup")
            defaults.set(true, forKey: "core")
            defaults.set(false, forKey: "oabutton")
            defaults.set(true, forKey: "oabrequest")
            defaults.set(true, forKey: "corerecom")
            defaults.set(true, forKey: "basehs")
            defaults.set(true, forKey: "corehs")
            defaults.set(false, forKey: "gettheresearchhs")
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
    
    func setValue(key: String, value: Bool){
        if let defaults = UserDefaults(suiteName: "J3PNNM2UXC.otzshare"){
            defaults.set(value, forKey: key)
        }
    }
}
