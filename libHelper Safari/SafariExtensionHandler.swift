//
//  SafariExtensionHandler.swift
//  libHelper Safari
//
//  Created by Claus Wolf on 28.10.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import Foundation
import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
    
    func readSettings() -> String{

        var text2 = ""
        let file = "ezproxy.text"
        
        let fileManager = FileManager.default
        guard let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "net.otzberg.shared") else {
            return ""
        }
        let safariExtDir = groupURL.appendingPathComponent("Library/Caches/")
        let fileURL = safariExtDir.appendingPathComponent(file)
        do {
            text2 = try String(contentsOf: fileURL, encoding: .utf8)
        }
        catch {
            text2 = "otzberg.net"
        }
        
        return text2
    }
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        
        if messageName == "found" {
            if let doi = userInfo?["doi"] {
                let mydoi = doi as! String
                checkUnpaywall(doi: mydoi, page: page)
            }
            
        }
        
        page.getPropertiesWithCompletionHandler { properties in
            NSLog("The extension received a message (\(messageName)) from a script injected into (\(String(describing: properties?.url))) with userInfo (\(userInfo ?? [:]))")
        }
    }
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        
        // This method will be called when your toolbar item is clicked.
        window.getActiveTab(completionHandler: { (activeTab) in
            
            activeTab?.getActivePage(completionHandler:  { (activePage) in
                
                activePage?.getPropertiesWithCompletionHandler( { (properties) in
                    
                    if properties?.url != nil {
                        let urlString = properties!.url!.absoluteString
                        
                        let url = URL(string: urlString)
                        let host = url?.host
                        let path = url?.path
                        let libproxy = self.readSettings()
                        
                        let newURLString = "http://" + libproxy + "/login?url=http://" + host! + path!
                        
                        let completeLibProxURL = URL(string: newURLString)
                        
                        window.openTab(with: completeLibProxURL!, makeActiveIfPossible: true, completionHandler: nil)
                        
                    }
                })
            })
        })
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        // This is called when Safari's state changed in some way that would require the extension's toolbar item to be validated again.
        validationHandler(true, "")
    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }
    
    override func popoverDidClose(in window: SFSafariWindow){
        window.getActiveTab { (activeTab) in
            activeTab?.getActivePage(completionHandler:  { (activePage) in
                activePage?.dispatchMessageToScript(withName: "doi", userInfo: nil);
            })
        }
        
    }
    
    func checkUnpaywall(doi: String, page: SFSafariPage) {
        
        let jsonUrlString = "https://www.otzberg.net/oadoiproxy/index.php?doi=\(doi)"
        
        let url = URL(string: jsonUrlString)
        
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            guard let data = data else { return }
            print(String(data: data, encoding: .utf8)!)
            self.handleData(data: data, page: page)
        }
        
        task.resume()
    }
    
    func handleData(data: Data, page: SFSafariPage){
        do{
            let oaData = try JSONDecoder().decode(OaDOI.self, from: data)
            page.dispatchMessageToScript(withName: "oafound", userInfo: [ "url" : oaData.url]);
        }
        catch let jsonError{
            print(jsonError)
            return
        }
    }
    
}


struct OaDOI : Decodable {
    let url : String
    let status : String
}

