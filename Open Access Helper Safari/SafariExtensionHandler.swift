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
                goToOaUrl(url: "\(url)")
            }
        }
        else if messageName == "searchOA"{
            searchOA(userInfo: (userInfo)!, type: 1)
        }
        else if messageName == "searchOA2"{
            searchOA(userInfo: (userInfo)!, type: 2)
        }
        else if messageName == "needIntlAlert"{
            if let msgId = userInfo?["msgId"] {
                returnIntlAlert(id: msgId as! String, page: page)
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
    
    // update context menu with the text selected by the user in Safari
    override func validateContextMenuItem(withCommand command: String, in page: SFSafariPage, userInfo: [String : Any]? = nil, validationHandler: @escaping (Bool, String?) -> Void){
        var selectedText = ""
        if let myUserInfo = userInfo{
            selectedText = myUserInfo["selectedText"] as! String
            var mySubstring = ""
            if (selectedText.count > 25){
                let index = selectedText.index(selectedText.startIndex, offsetBy: 25)
                mySubstring = "\(String(selectedText[..<index]))…"
            }
            else{
                mySubstring = selectedText
            }
            var myContextLabel = String(format: NSLocalizedString("base-search.net search for: \"%@\"", comment: "changes Context Label"), String(mySubstring))
            if(command == "oasearch"){
                myContextLabel = String(format: NSLocalizedString("base-search.net search for: \"%@\"", comment: "changes Context Label"), String(mySubstring))
            }
            else if(command == "oasearch2"){
                myContextLabel = String(format: NSLocalizedString("core.ac.uk search for: \"%@\"", comment: "changes Context Label"), String(mySubstring))
            }
            
            validationHandler(false, myContextLabel)
        }
        
    }
    
    
    //construct the URL and open a new tab
    override func contextMenuItemSelected(withCommand command: String, in page: SFSafariPage, userInfo: [String : Any]? = nil) {
        
        if let myUserInfo = userInfo{
            var selectedText = ""
            selectedText = myUserInfo["selectedText"] as! String
            let searchTerm = selectedText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            var myurl = "https://www.base-search.net/Search/Results?lookfor=%22\(searchTerm!)%22&name=&oaboost=1&newsearch=1&l=en"
            if(command == "oasearch"){
               myurl = "https://www.base-search.net/Search/Results?lookfor=%22\(searchTerm!)%22&name=&oaboost=1&newsearch=1&l=en"
            }
            else if(command == "oasearch2"){
               myurl = "https://core.ac.uk/search?q=%22\(searchTerm!)%22"
            }
        
            if(command == "oasearch" || command == "oasearch2"){
                updateOASearchCount()
                goToOaUrl(url: myurl)
            }
        }

    }
    
    func searchOA(userInfo: [String : Any], type: Int){
        if let selectedText = userInfo["selected"]{
            let selectedText1 = "\(selectedText)"
            let searchTerm = selectedText1.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            var myurl = "https://www.base-search.net/Search/Results?lookfor=%22\(searchTerm!)%22&name=&oaboost=1&newsearch=1&l=en"
            if(type == 1){
                myurl = "https://www.base-search.net/Search/Results?lookfor=%22\(searchTerm!)%22&name=&oaboost=1&newsearch=1&l=en"
            }
            else if(type == 2){
                myurl = "https://core.ac.uk/search?q=%22\(searchTerm!)%22"
            }
            
            updateOASearchCount()
            goToOaUrl(url: myurl)
            
        }

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
        let jsonUrlString = "https://api.unpaywall.org/v2/\(doi)?email=oahelper@otzberg.net"
        let url = URL(string: jsonUrlString)
        
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                self.toolbarAction(imgName: "oa_100.pdf")
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
                    let title = NSLocalizedString("Open Access Version Found! ", comment: "used in JS injection to indicate OA found")
                    page.dispatchMessageToScript(withName: "oafound", userInfo: [ "url" : "\(boa.url)", "title" : title])
                }
                else{
                    toolbarAction(imgName: "oa_100.pdf")
                    page.dispatchMessageToScript(withName: "notoadoi", userInfo: nil)
                }
            }
            else {
                toolbarAction(imgName: "oa_100.pdf")
                page.dispatchMessageToScript(withName: "notoadoi", userInfo: nil)
            }
            
            
        }
        catch let jsonError{
            NSLog("\(jsonError)")
            //page.dispatchMessageToScript(withName: "printPls", userInfo: ["handleData_error" : "\(jsonError)"])
            toolbarAction(imgName: "oa_100.pdf")
            page.dispatchMessageToScript(withName: "notoadoi", userInfo: nil)
            return
        }
    }
    
    func followLink(current: String, next: String, page: SFSafariPage){
        
        //before we run any network traffic, let's check, if we are on OA already
        // first option is "failed"
        if(!compareFinalURLs(current: current, next: next, page: page)){
            //follow link
            runUrlCall(current: current, next: next, page: page)
        }
        else{
            self.toolbarAction(imgName: "oa_100a.pdf")
            self.updateBadge(text: "✔")
            let title = NSLocalizedString("You are at the Open Acccess Location!", comment: "used in JS confirm that you are on OA already")
            page.dispatchMessageToScript(withName: "onoa", userInfo: ["title" : title]);
        }
        
    }
    
    func runUrlCall(current: String, next: String, page: SFSafariPage) {
        let url = URL(string: next)
        //NSLog("OAURLCALL: \(next)")
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                // known issue, as soon as we hit watermark.silverchair.com the connection is dropped :(
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["error" : error.localizedDescription])
            }
            guard let response = response else {
                return
            }
            if let finalUrl = response.url{
                
                if(self.compareFinalURLs(current: current, next: "\(finalUrl)", page: page)){
                    self.toolbarAction(imgName: "oa_100a.pdf")
                    self.updateBadge(text: "✔")
                    let title = NSLocalizedString("You are at the Open Acccess Location!", comment: "used in JS confirm that you are on OA already")
                    page.dispatchMessageToScript(withName: "onoa", userInfo: ["title" : title]);
                }
                else{
                    // do nothing, i.e. keep old state in tact
                }
                
            }
        }
        
        task.resume()
    }
    
    func compareFinalURLs(current: String, next: String, page: SFSafariPage) -> Bool{
        
        //remove http and https to avoid trouble in the comparison
        let finalUrlString = "\(next)"
        
        var myFinalUrl = finalUrlString.replacingOccurrences(of: "https://", with: "")
        myFinalUrl = myFinalUrl.replacingOccurrences(of: "http://", with: "")
        var myCurrent = current.replacingOccurrences(of: "https://", with: "")
        myCurrent = myCurrent.replacingOccurrences(of: "http://", with: "")
        
        let cUrl1 = URL(string: current)
        let next1 = URL(string: next)
        let domain1 = cUrl1?.host
        let domain2 = next1?.host
        
        if (myFinalUrl == myCurrent){
            return true
        }
        else if (domain1 == domain2){
            return true
        }
        else if (domain1 == "www.sciencedirect.com" && domain2 == "linkinghub.elsevier.com"){
            return true
        }
        else if (current.contains("www.ncbi.nlm.nih.gov/pmc/")){
            return true
        }
        else{
            return false
        }
        
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
    
    func returnIntlAlert(id: String, page: SFSafariPage){
        var msg = ""
        var type = ""
        if (id == "oahdoire_0") {
            msg = NSLocalizedString("Open Access Helper could not find a legal open-access version of this article.", comment: "will show in JS Alert, when there was a doi, but no oadoi url")
            type = "alert"
        }
        else if(id == "oahdoire_1"){
            msg = NSLocalizedString("Open Access Helper is inactive on this page, as we could not identify a DOI\n\nClick OK to learn more about this app\nClick Cancel to dismiss this message", comment: "will show in JS Alert, when there no doi = inactive state")
            type = "confirm"
        }
        if(msg != ""){
            page.dispatchMessageToScript(withName: "showAlert", userInfo: ["msg" : msg, "type" : type]);
        }
    }

    
    func updateCount(){
        let count = readCount(file: "count.txt")
        let new = count + 1
        writeCount(count: "\(new)", file: "count.txt")
    }
    
    func updateOASearchCount(){
        let count = readCount(file: "oacount.txt")
        let new = count + 1
        writeCount(count: "\(new)", file: "oacount.txt")
    }
    
    
    func writeCount(count: String, file: String ) {
        let file = file //this is the file. we will write to and read from it
        
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

    func readCount(file: String) -> Int{
        let file = file //this is the file. we will write to and read from it
        
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
    let journal_issns : String?
    let journal_name : String?
    let oa_locations : [OpenAccessLocation]
    let published_date : String?
    let publisher : String?
    let title : String?
    let updated : String?
    let year : Int?
    let z_authors : [OAAuthors]?
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
    let version : String?
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
