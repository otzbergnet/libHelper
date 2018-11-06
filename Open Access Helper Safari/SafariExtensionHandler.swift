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
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        if messageName == "found" {
            if let doi = userInfo?["doi"] {
                let mydoi = doi as! String
                checkUnpaywall(doi: mydoi, page: page)
            }
            
        }
        else if messageName == "compareURL" {
            var currentUrl = ""
            var goToUrl = ""
            if let current = userInfo?["current"] {
                currentUrl = current as! String
            }
            if let next = userInfo?["goto"] {
                goToUrl = next as! String
            }
            if(currentUrl != "" && goToUrl != ""){
                followLink(current: currentUrl, next: goToUrl, page: page)
            }
        }
        else if messageName == "notfound" {
            toolbarAction(imgName: "oa_100.pdf")
            updateBadge(text: "remove")
        }
        else if messageName == "oaURLReturn"{
            if let url = userInfo?["oaurl"] {
                goToOaUrl(url: "\(url)");
            }
            
        }
        
        page.getPropertiesWithCompletionHandler { properties in
            NSLog("The extension received a message (\(messageName)) from a script injected into (\(String(describing: properties?.url))) with userInfo (\(userInfo ?? [:]))")
        }
    }
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        
        window.getActiveTab(completionHandler: { (activeTab) in
            
            activeTab?.getActivePage(completionHandler:  { (activePage) in
                
                activePage?.getPropertiesWithCompletionHandler( { (properties) in
                    activePage?.dispatchMessageToScript(withName: "getOAUrl", userInfo: [:])
                })
            })
        })

    }
    
    func goToOaUrl(url: String){
        SFSafariApplication.getActiveWindow { (window) in
            if let myUrl = URL(string: url) {
                window?.openTab(with: myUrl, makeActiveIfPossible: true, completionHandler: nil)
            }
            
        }
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
        toolbarAction(imgName: "oa_100a.pdf")
        let jsonUrlString = "https://api.unpaywall.org/v2/\(doi)?email=claus.wolf@otzberg.net"
        let url = URL(string: jsonUrlString)
        
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["unpaywall_error" : error.localizedDescription])
            }
            if let data = data {
                self.handleData(data: data, page: page)
            }
            else{
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["unpaywall_data" : "failed"])
                self.toolbarAction(imgName: "oa_100.pdf")
                return
            }
            
        }

        task.resume()
    }
    
    func handleData(data: Data, page: SFSafariPage){
        //sole purpose is to dispatch the url
        do{
            let oaData = try JSONDecoder().decode(Unpaywall.self, from: data)
            if let boa = oaData.best_oa_location {
                if (boa.url != "") {
                    updateBadge(text: "!")
                    updateCount()
                    page.dispatchMessageToScript(withName: "oafound", userInfo: [ "url" : "\(boa.url)"])
                }
                else{
                    toolbarAction(imgName: "oa_100.pdf")
                }
            }
            else {
                toolbarAction(imgName: "oa_100.pdf")
            }
            
            
        }
        catch let jsonError{
            NSLog("\(jsonError)")
            //page.dispatchMessageToScript(withName: "printPls", userInfo: ["handleData_error" : "\(jsonError)"])
            return
        }
    }
    
    func followLink(current: String, next: String, page: SFSafariPage){
        
        let url = URL(string: next)
        
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["error" : error.localizedDescription])
            }
            guard let response = response else {
                return
            }
            if let finalUrl = response.url{
                
                //remove http and https to avoid trouble in the comparison
                let finalUrlString = "\(finalUrl)"

                var myFinalUrl = finalUrlString.replacingOccurrences(of: "https://", with: "")
                myFinalUrl = myFinalUrl.replacingOccurrences(of: "http://", with: "")
                var myCurrent = current.replacingOccurrences(of: "https://", with: "")
                myCurrent = myCurrent.replacingOccurrences(of: "http://", with: "")

                let cUrl1 = URL(string: current)
                let domain1 = cUrl1?.host
                let domain2 = finalUrl.host
                
                
                //simple string comparison
                if (myFinalUrl == myCurrent){
                    self.toolbarAction(imgName: "oa_100a.pdf")
                    self.updateBadge(text: "✔")
                    page.dispatchMessageToScript(withName: "onoa", userInfo: [:]);
                }
                else if (domain1 == domain2){
                    self.toolbarAction(imgName: "oa_100a.pdf")
                    self.updateBadge(text: "✔")
                    page.dispatchMessageToScript(withName: "onoa", userInfo: [:]);
                }
                else if (domain1 == "www.sciencedirect.com" && domain2 == "linkinghub.elsevier.com"){
                    self.toolbarAction(imgName: "oa_100a.pdf")
                    self.updateBadge(text: "✔")
                    page.dispatchMessageToScript(withName: "onoa", userInfo: [:]);
                }
                else if (current.contains("www.ncbi.nlm.nih.gov/pmc/")){
                    self.toolbarAction(imgName: "oa_100a.pdf")
                    self.updateBadge(text: "✔")
                    page.dispatchMessageToScript(withName: "onoa", userInfo: [:]);
                }
                
            }
        }
        
        task.resume()
    }
    
    func toolbarAction(imgName: String){
        let image = NSImage(named: imgName)
        SFSafariApplication.getActiveWindow { (window) in
            window?.getToolbarItem { $0?.setImage(image) }
        }
    }
    
    func updateBadge(text: String){
        if (text == "remove"){
            SFSafariApplication.getActiveWindow { (window) in
                window?.getToolbarItem { $0?.setBadgeText(nil)}
            }
        }
        else{
            SFSafariApplication.getActiveWindow { (window) in
                window?.getToolbarItem { $0?.setBadgeText(text)}
            }
        }
        
    }

    
    func updateCount(){
        let count = readCount()
        let new = count + 1
        writeCount(count: "\(new)")
    }
    
    
    func writeCount(count: String ) {
        let file = "count.txt" //this is the file. we will write to and read from it
        
        let text = count //just a text
        
        let fileManager = FileManager.default
        guard let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "J3PNNM2UXC.otzshare") else {
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

    func readCount() -> Int{
        let file = "count.txt" //this is the file. we will write to and read from it
        
        var text2 = "0"
        
        let fileManager = FileManager.default
        guard let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "J3PNNM2UXC.otzshare") else {
            return 0
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
        
        return Int(text2)!
    }
    
}




struct OaDOI : Decodable {
    let url : String
    //let final : String
    let status : String
}

struct Unpaywall : Decodable{
    let best_oa_location : OpenAccessLocation?
    let data_standard : Int
    let doi : String
    let doi_url : String
    let genre : String
    let is_oa : Bool
    let journal_is_in_doaj: Bool
    let journal_is_oa : Bool
    let journal_issns : String
    let journal_name : String
    let oa_locations : [OpenAccessLocation]
    let published_date : String
    let publisher : String
    let title : String
    let updated : String?
    let year : Int
    let z_authors : [OAAuthors]
}

struct OpenAccessLocation : Decodable {
    let evidence : String
    let host_type : String
    let is_best : Bool
    let license : String?
    let pmh_id : String?
    let updated : String?
    let url : String
    let url_for_landing_page : String?
    let url_for_pdf : String?
    let version : String
}

struct OAAuthors : Decodable{
    
    let orcid : String?
    let authenticated_orcid : Bool?
    let family : String?
    let given : String?
    let sequence : String?
    
    enum CodingKeys: String, CodingKey {
        case authenticated_orcid = "authenticated-orcid"
        case orcid = "ORCID"
        case family = "family"
        case given = "given"
        case sequence = "sequence"
    }
}
