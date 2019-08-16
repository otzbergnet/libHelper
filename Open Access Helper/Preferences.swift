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
            return defaults.bool(forKey: "setup")
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
            defaults.set(false, forKey: "oabrequest")
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
}
