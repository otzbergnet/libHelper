//
//  SafariExtensionHandler.swift
//  libHelper Safari
//
//  Created by Claus Wolf on 28.10.18.
//  Copyright © 2018-2021 Claus Wolf. All rights reserved.
//

import Foundation
import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
    
    let preferences = Preferences()
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        if messageName == "found" {
            if let doi = userInfo?["doi"] {
                let mydoi = doi as! String
                if let url = userInfo?["url"]{
                    let myUrl = url as! String
                    checkUnpaywall(doi: mydoi, page: page, originUrl: myUrl)
                    //checkOAButton(doi: mydoi, page: page, originUrl: myUrl)
                }
                else{
                    let myUrl = ""
                    checkUnpaywall(doi: mydoi, page: page, originUrl: myUrl)
                    //checkOAButton(doi: mydoi, page: page, originUrl: myUrl)
                }
                
            }
            else{
                NSLog("OAHELPER: LOST in MESSAGE RECEIVED")
            }
            
        }
        else if messageName == "compareURL" {
            var currentUrl = ""
            var goToUrl = ""
            if let current = userInfo?["current"] {
                currentUrl = current as? String ?? ""
            }
            if let next = userInfo?["goto"] {
                goToUrl = next as? String ?? ""
            }
            if(currentUrl != "" && goToUrl != ""){
                followLink(current: currentUrl, next: goToUrl, page: page)
            }
        }
        else if messageName == "notfound" {
            toolbarAction(imgName: "oahelper_black.pdf")
            updateBadge(text: "remove")
        }
        else if messageName == "oaURLReturn"{
            let ezproxyPrefix = self.preferences.getStringValue(key: "ezproxyPrefix")
            guard let oaurl = userInfo?["oaurl"] else{
                return
            }
            let actionUrl = "\(oaurl)"
            if(ezproxyPrefix != "" && actionUrl.contains(ezproxyPrefix)){
                page.dispatchMessageToScript(withName: "removeProxy", userInfo: ["msg" : "removeproxy", "ezproxy" : ezproxyPrefix])
            }
            else if(actionUrl.contains("openaccessbutton") && ezproxyPrefix != ""){
                updateEzProxyCount()
                page.dispatchMessageToScript(withName: "addProxy", userInfo: ["msg" : "addproxy", "ezproxy" : ezproxyPrefix])
            }
            else if(actionUrl == "pleaseproxy" && ezproxyPrefix != ""){
                updateEzProxyCount()
                page.dispatchMessageToScript(withName: "addProxy", userInfo: ["msg" : "addproxy", "ezproxy" : ezproxyPrefix])
            }
            else{
                if let url = userInfo?["oaurl"] {
                    goToOaUrl(url: "\(url)")
                }
            }
            
        }
        else if messageName == "searchOA"{
            searchOA(userInfo: (userInfo)!, type: "oasearch")
        }
        else if messageName == "needIntlAlert"{
            if let msgId = userInfo?["msgId"] {
                returnIntlAlert(id: msgId as! String, page: page)
            }
        }
        else if messageName == "badgeUpdate"{
            let badge = userInfo?["badge"] as! String
            if(badge == "!" || badge == "✔"){
                updateBadge(text: "\(badge)")
                self.toolbarAction(imgName: "oahelper_black_filled.pdf")
            }
            else{
                self.toolbarAction(imgName: "oahelper_black.pdf")
            }
        }
        else if messageName == "doCoreRecom"{
            if(preferences.getValue(key: "corerecom")){
                if let doiString = userInfo?["doistring"]{
                    let infoString = NSLocalizedString("We are preparing a list of fresh papers similar to what you are looking for. Hang on tight :)", comment: "infoString for waiting for recommendations to load")
                    let closeLabel = NSLocalizedString("close", comment: "shows as part of the phras x Close in the Core Recommender")
                    page.dispatchMessageToScript(withName: "doCoreRecom", userInfo: ["doistring" : doiString, "infoString" : infoString, "closeLabel" : closeLabel])
                }
            }
        }
        else if messageName == "requestRecommendation" {
            //"requestRecommendation", {"doi" : doi, "currentUrl" : currentUrl, "docTitle" : docTitle, "abstract" : abstract}
            if(preferences.getValue(key: "corerecom")){
                self.requestRecommendation(userInfo: (userInfo)!, page: page)
            }
        }
        else if messageName == "getconsolelog"{
            let consoleLogStatus = preferences.getValue(key: "noconsolelog");
            page.dispatchMessageToScript(withName: "consolelog_configuration", userInfo: ["consolelog" : consoleLogStatus])
        }
        else if messageName == "request_citations"{
            if let doi  = userInfo?["doi"]{
                self.findOpenCitations(doi: doi as! String, page: page)
            }
        }
        else if messageName == "currentState"{

            let myPopupAnswer = PopupAnswer()
            myPopupAnswer.citationCount = userInfo?["citationcount"] as! Int
            myPopupAnswer.citationUrl = userInfo?["citationurl"] as! String
            myPopupAnswer.currentUrl = userInfo?["currenturl"] as! String
            myPopupAnswer.doi = userInfo?["doi"] as! String
            myPopupAnswer.isIll = userInfo?["isIll"] as! String
            myPopupAnswer.oastatus = userInfo?["oastatus"] as! String
            myPopupAnswer.oaurl = userInfo?["oaurl"] as! String
            SafariExtensionViewController.shared.createPopover(popupAnswer: myPopupAnswer)
            
        }
        else if messageName == "popoverAction" {
            SFSafariApplication.getActiveWindow { (window) in
                window?.getToolbarItem { $0?.showPopover()}
            }
        }
        
        updateSettingsFromServer()
        
    }
    
//    override func toolbarItemClicked(in window: SFSafariWindow) {
//
//        window.getActiveTab(completionHandler: { (activeTab) in
//
//            activeTab?.getActivePage(completionHandler:  { (activePage) in
//
//                activePage?.getPropertiesWithCompletionHandler( { (properties) in
//                    activePage?.dispatchMessageToScript(withName: "getOAUrl", userInfo: [:])
//                })
//            })
//        })
//
//    }
    
    // update context menu with the text selected by the user in Safari
    override func validateContextMenuItem(withCommand command: String, in page: SFSafariPage, userInfo: [String : Any]? = nil, validationHandler: @escaping (Bool, String?) -> Void){
        var selectedText = ""
        
        //get search engine
        let searchEngineTag = preferences.getIntVal(key: "searchengine")
        
        var searchEngine = [String]()
        searchEngine.insert("Open Access", at: 0)
        searchEngine.insert("base-search.net", at: 1)
        searchEngine.insert("core.ac.uk", at: 2)
        searchEngine.insert("scholar.google.com", at: 3)
        searchEngine.insert("semanticscholar.org", at: 4)
        searchEngine.insert("app.dimensions.ai", at: 5)
        searchEngine.insert("Microsoft Academic", at: 6)
        
        
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
            
            var myContextLabel = "\(searchEngine[searchEngineTag])\(String(format: NSLocalizedString(" search for: \"%@\"", comment: "changes Context Label"), String(mySubstring)))"
            
            if(command == "oasearch" && selectedText.count > 0){
                myContextLabel = "\(searchEngine[searchEngineTag])\(String(format: NSLocalizedString(" search for: \"%@\"", comment: "changes Context Label"), String(mySubstring)))"
            }
            else if(command == "oasearch" && selectedText.count == 0){
                myContextLabel = "\(String(format: NSLocalizedString("Visit ", comment: "changes Context Label, base-search-net"), String(mySubstring)))\(searchEngine[searchEngineTag])"
            }

            //we only have one command so we are not even going to check
            
            if(searchEngineTag > 0){
//                print("searchEngineTag \(searchEngineTag) greater 0")
                validationHandler(false, myContextLabel)
            }
            else{
//                print("searchEngineTag equals 0")
                validationHandler(true, nil)
            }
            
        }
        
    }
    
    
    //construct the URL and open a new tab, when text is selected and the context menu is selected
    override func contextMenuItemSelected(withCommand command: String, in page: SFSafariPage, userInfo: [String : Any]? = nil) {
        
        if let myUserInfo = userInfo{
            var selectedText = ""
            selectedText = myUserInfo["selectedText"] as! String
            
            let myurl = createOASearchURL(originalTextSelection: selectedText, command: command)
            
            if(command != ""){
                if(selectedText.count > 0){
                    updateOASearchCount()
                }
                goToOaUrl(url: myurl)
            }
        }
        
    }
    
    
    // this one gets executed when the keyboard shortcut (ctrl+alt+o) is pressed and text is selected
    func searchOA(userInfo: [String : Any], type: String){
        if let selectedText = userInfo["selected"]{
            let selectedText1 = "\(selectedText)"
            let myurl = createOASearchURL(originalTextSelection: selectedText1, command: type)
            
            updateOASearchCount()
            goToOaUrl(url: myurl)
            
        }
    }
    
    func createOASearchURL(originalTextSelection: String, command: String) -> String{
        let searchTerm = originalTextSelection.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let count = originalTextSelection.count
        let searchEngineTag = preferences.getIntVal(key: "searchengine")
        //default to always return something
        var myurl = "https://www.base-search.net/Search/Results?lookfor=%22\(searchTerm!)%22&name=&oaboost=1&newsearch=1&l=en"
        
        if(command == "oasearch" && count > 0 && searchEngineTag == 1){ // base-search-net
            myurl = "https://www.base-search.net/Search/Results?lookfor=%22\(searchTerm!)%22&name=&oaboost=1&newsearch=1&l=en"
        }
        else if(command == "oasearch" && count == 0 && searchEngineTag == 1){
            myurl = "https://www.base-search.net/"
        }
        else if(command == "oasearch" && count > 0 && searchEngineTag == 2){ //core.ac.uk
            myurl = "https://core.ac.uk/search?q=\(searchTerm!)"
        }
        else if(command == "oasearch" && count == 0 && searchEngineTag == 2){
            myurl = "https://core.ac.uk/"
        }
        else if(command == "oasearch" && count > 0 && searchEngineTag == 3){ // microsoft academic
            myurl = "https://scholar.google.com/scholar?q=\(searchTerm!)"
        }
        else if(command == "oasearch" && count == 0 && searchEngineTag == 3){
            myurl = "https://scholar.google.com"
        }
        else if(command == "oasearch" && count > 0 && searchEngineTag == 4){ // semantic
            myurl = "https://www.semanticscholar.org/search?q=\(searchTerm!)&sort=relevance"
        }
        else if(command == "oasearch" && count == 0 && searchEngineTag == 4){
            myurl = "https://www.semanticscholar.org/"
        }
        else if(command == "oasearch" && count > 0 && searchEngineTag == 5){  // Dimensions
            myurl = "https://app.dimensions.ai/discover/publication?search_mode=content&search_text=\(searchTerm!)&search_type=kws&search_field=full_search"
        }
        else if(command == "oasearch" && count == 0 && searchEngineTag == 5){
            myurl = "https://app.dimensions.ai/"
        }
        else if(command == "oasearch" && count > 0 && searchEngineTag == 6){  // Dimensions
            myurl = "https://academic.microsoft.com/search?q=\(searchTerm!)&f=&orderBy=0&skip=0&take=10"
        }
        else if(command == "oasearch" && count == 0 && searchEngineTag == 6){
            myurl = "https://academic.microsoft.com/home"
        }
        
        return myurl
    }
    
    func goToOaUrl(url: String){
        SFSafariApplication.getActiveWindow { (window) in
            if let myUrl = URL(string: url) {
                window?.openTab(with: myUrl, makeActiveIfPossible: true, completionHandler: { (tab) in
                    print("opened the tab")
                })
            }
        }
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        
        // This is called when Safari's state changed in some way that would require the extension's toolbar item to be validated again.
        window.getActiveTab { (activeTab) in
            activeTab?.getActivePage(completionHandler:  { (activePage) in
                activePage?.dispatchMessageToScript(withName: "tabevaluate", userInfo: nil);
            })
        }
        self.toolbarAction(imgName: "oahelper_black.pdf")
        validationHandler(true, "")
        
    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }
       
    override func popoverDidClose(in window: SFSafariWindow){
        window.getActiveTab { (activeTab) in
            activeTab?.getActivePage(completionHandler:  { (activePage) in
                //activePage?.dispatchMessageToScript(withName: "doi", userInfo: nil);
            })
        }
    }
    
    func checkUnpaywall(doi: String, page: SFSafariPage, originUrl: String) {
        toolbarAction(imgName: "oahelper_black_filled.pdf")
        let jsonUrlString = "https://api.unpaywall.org/v2/\(doi)?email=oahelper@otzberg.net"
        let url = URL(string: jsonUrlString)
        
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                self.toolbarAction(imgName: "oahelper_black.pdf")
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["unpaywall_error" : error.localizedDescription])
                self.checkCore(doi: doi, page: page, originUrl: originUrl, year: 1)
            }
            if let data = data {
                self.handleData(data: data, page: page, doi: doi, originUrl: originUrl)
            }
            else{
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["unpaywall_data" : "failed"])
                self.toolbarAction(imgName: "oahelper_black.pdf")
                self.checkCore(doi: doi, page: page, originUrl: originUrl, year: 1)
                return
            }
            
        }
        
        task.resume()
    }
    
    func handleData(data: Data, page: SFSafariPage, doi: String, originUrl: String){
        //sole purpose is to dispatch the url
        do{
            let oaData = try JSONDecoder().decode(Unpaywall.self, from: data)
            if let boa = oaData.best_oa_location {
                if (boa.url != "") {
                    toolbarAction(imgName: "oahelper_black_filled.pdf")
                    updateBadge(text: "!")
                    updateCount()
                    let oaVersion = self.getOpenAccessVersion(data: oaData)
                    let title = NSLocalizedString("Open Access Version Found from unpaywall.org! ", comment: "used in JS injection to indicate OA found")
                    page.dispatchMessageToScript(withName: "oafound", userInfo: [ "url" : "\(boa.url)", "title" : title, "source" : "unpaywall.org", "version" : "\(oaVersion)", "doi" : doi])
                    self.findOpenCitations(doi: doi, page: page)
                }
                else{
                    toolbarAction(imgName: "oahelper_black.pdf")
                    //page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "y"])
                    if let year = oaData.year {
                        self.checkCore(doi: doi, page: page, originUrl: originUrl, year: year)
                    }
                    else{
                        self.checkCore(doi: doi, page: page, originUrl: originUrl, year: 0)
                    }
                    
                }
            }
            else {
                toolbarAction(imgName: "oahelper_black.pdf")
                //page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "y"])
                if let year = oaData.year {
                    self.checkCore(doi: doi, page: page, originUrl: originUrl, year: year)
                }
                else{
                    self.checkCore(doi: doi, page: page, originUrl: originUrl, year: 0)
                }
            }
            
            
        }
        catch let jsonError{
            NSLog("\(jsonError)")
            //page.dispatchMessageToScript(withName: "printPls", userInfo: ["handleData_error" : "\(jsonError)"])
            toolbarAction(imgName: "oahelper_black.pdf")
            //page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "y"])
            self.checkCore(doi: doi, page: page, originUrl: originUrl, year: 1)
            return
        }
    }
    
    
    func checkCore(doi: String, page: SFSafariPage, originUrl: String, year: Int) {
        let coreSetting = preferences.getValue(key: "core")
        let oaButtonSetting = preferences.getValue(key: "oabutton")
        if(!coreSetting && !oaButtonSetting){
            // user wants neither core nor open access button
            // let's take them to potential order button
            noOpenAccessFound(page: page, doi: doi, year: year)
            return
        }
        else if(!coreSetting && oaButtonSetting){
            //client doesn't want core, but wants Open Access Button
            self.checkOAButton(doi: doi, page: page, originUrl: originUrl, year: year)
            return
        }
        // if we got here the client wants core
        
        toolbarAction(imgName: "oahelper_black_filled.pdf")
        
        //make request JSON
        let json: [String: Any] = ["doi": doi]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        //prepare API call
        let apiKey = self.getAPIKeyFromPlist(type: "core")
        let jsonUrlString = "https://api.core.ac.uk/v3/discover"
        guard let url = URL(string: jsonUrlString) else {
            return
        }
        //setup POST REQUEST
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                self.toolbarAction(imgName: "oahelper_black.pdf")
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["core.ac.uk_error" : error.localizedDescription])
                self.checkOAButton(doi: doi, page: page, originUrl: originUrl, year: 1)
            }
            if let data = data {
                self.handleCoreData(data: data, doi: doi, originUrl: originUrl, page: page, year: year)
                self.findOpenCitations(doi: doi, page: page)
            }
            else{
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["core.ac.uk_data" : "failed"])
                self.toolbarAction(imgName: "oahelper_black.pdf")
                self.checkOAButton(doi: doi, page: page, originUrl: originUrl, year: 1)
                return
            }
            
        }
        
        task.resume()
    }
    
    func handleCoreData(data: Data, doi: String, originUrl: String, page: SFSafariPage, year: Int){
        //sole purpose is to dispatch the url
        do{
            let coreData = try JSONDecoder().decode(Coredata.self, from: data)
            print(coreData)
            if let boa = coreData.fullTextLink {
                if (boa != "") {
                    toolbarAction(imgName: "oahelper_black_filled.pdf")
                    updateBadge(text: "!")
                    updateCount()
                    let title = NSLocalizedString("Open Access Version Found from core.ac.uk! ", comment: "used in JS injection to indicate OA found")
                    page.dispatchMessageToScript(withName: "oafound", userInfo: [ "url" : "\(boa)", "title" : title, "source" : "core.ac.uk", "version" : "", "doi" : doi])
                }
                else{
                    toolbarAction(imgName: "oahelper_black.pdf")
                    //page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "y"])
                    self.checkOAButton(doi: doi, page: page, originUrl: originUrl, year: year)
                }
            }
            else {
                toolbarAction(imgName: "oahelper_black.pdf")
                //page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "y"])
                self.checkOAButton(doi: doi, page: page, originUrl: originUrl, year: year)
            }
            
            
        }
        catch let jsonError{
            NSLog("\(jsonError)")
            //page.dispatchMessageToScript(withName: "printPls", userInfo: ["handleData_error" : "\(jsonError)"])
            toolbarAction(imgName: "oahelper_black.pdf")
            //page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "y"])
            self.checkOAButton(doi: doi, page: page, originUrl: originUrl, year: 1)
            return
        }
    }
    
    
    func checkOAButton(doi: String, page: SFSafariPage, originUrl: String, year: Int) {
        let oaButtonSetting = preferences.getValue(key: "oabutton")
        if(!oaButtonSetting){
            noOpenAccessFound(page: page, doi: doi, year: year)
            return
        }
        
        //if user got here, they want the Open Access Button Check
        toolbarAction(imgName: "oahelper_black_filled.pdf")
        let apiKey = self.getAPIKeyFromPlist(type: "oabutton")
        if(apiKey == ""){
            self.toolbarAction(imgName: "oahelper_black.pdf")
            return
        }
        
        let jsonUrlString = "https://api.openaccessbutton.org/availability?url=\(originUrl)&doi=\(doi)"
        let url = URL(string: jsonUrlString)
        
        let session = URLSession.shared
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(apiKey)", forHTTPHeaderField: "x-apikey")
        
        let task = session.dataTask(with: request) {(data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["oa_button_error" : error.localizedDescription])
                NSLog("OAHELPER: OAB ERROR in dataTask / error")
                self.noOpenAccessFound(page: page, doi: doi, year: year)
            }
            if let data = data {
                self.handleOAButtonData(data: data, page: page, originUrl: originUrl, year: year, doi: doi)
            }
            else{
                NSLog("OAHELPER: OAB ERROR in dataTask / else")
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["oa_button_data" : "failed"])
                self.noOpenAccessFound(page: page, doi: doi, year: year)
                return
            }
            
        }
        
        task.resume()
    }
    
    func handleOAButtonData(data: Data, page: SFSafariPage, originUrl : String, year: Int, doi: String){
        do{
            let oaButtonData = try JSONDecoder().decode(OaButton.self, from: data)
            if let oabAvailability = oaButtonData.data.availability {
                if let targetUrl = oabAvailability.first??.url{
                    if (targetUrl != "") {
                        toolbarAction(imgName: "oahelper_black_filled.pdf")
                        updateBadge(text: "!")
                        updateCount()
                        let title = NSLocalizedString("Open Access Version Found from Open Access Button ", comment: "used in JS injection to indicate OA found")
                        page.dispatchMessageToScript(withName: "oafound", userInfo: [ "url" : "\(targetUrl)", "title" : title, "source" : "Open Access Button", "version" : "", "doi" : doi])
                        self.findOpenCitations(doi: doi, page: page)
                    }
                    else{
                        noOpenAccessFound(page: page, doi: doi, year: year)
                    }
                }
                else{
                    if let oabRequests = oaButtonData.data.requests {
                        if let requestId = oabRequests.first??.id {
                            self.checkOAButtonRequest(request: requestId, page: page, originUrl: originUrl, year: year, doi: doi)
                        }
                        else{
                            noOpenAccessFound(page: page, doi: doi, year: year)
                        }
                    }
                    else{
                        noOpenAccessFound(page: page, doi: doi, year: year)
                    }
                }
                
            }
            else {
                noOpenAccessFound(page: page, doi: doi, year: year)
                
            }
        }
        catch let jsonError{
            page.dispatchMessageToScript(withName: "printPls", userInfo: ["handleData_error" : "\(jsonError)"])
            noOpenAccessFound(page: page, doi: doi, year: year)
            
            return
        }
    }
    
    
    func checkOAButtonRequest(request: String, page: SFSafariPage, originUrl: String, year: Int, doi: String) {
        toolbarAction(imgName: "oahelper_black_filled.pdf")
        let apiKey = self.getAPIKeyFromPlist(type: "oabutton")
        if(apiKey == ""){
            self.toolbarAction(imgName: "oahelper_black.pdf")
            return
        }
        
        let jsonUrlString = "https://api.openaccessbutton.org/request/\(request)"
        let url = URL(string: jsonUrlString)
        
        let session = URLSession.shared
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(apiKey)", forHTTPHeaderField: "x-apikey")
        
        let task = session.dataTask(with: request) {(data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["oa_button_error" : error.localizedDescription])
                self.noOpenAccessFound(page: page, doi: doi, year: year)
                
            }
            if let data = data {
                self.handleOABRequestData(data: data, page: page, originUrl: originUrl, year: year, doi: doi)
            }
            else{
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["oa_button_data" : "failed"])
                self.noOpenAccessFound(page: page, doi: doi, year: year)
                return
            }
            
        }
        
        task.resume()
    }
    
    func handleOABRequestData(data: Data, page: SFSafariPage, originUrl : String, year: Int, doi: String){
        do{
            let oaButtonData = try JSONDecoder().decode(OARequestData.self, from: data)
            if let status = oaButtonData.data.status{
                if(status == "received"){
                    if let received = oaButtonData.data.received{
                        if let url = received.url{
                            if(url != ""){
                                toolbarAction(imgName: "oahelper_black_filled.pdf")
                                updateBadge(text: "!")
                                updateCount()
                                let title = NSLocalizedString("Open Access Version Found from Open Access Button ", comment: "used in JS injection to indicate OA found")
                                page.dispatchMessageToScript(withName: "oafound", userInfo: [ "url" : "\(url)", "title" : title, "source" : "Open Access Button", "version" : "", "doi" : doi])
                            }
                            else{
                                noOpenAccessFound(page: page, doi: doi, year: year)
                            }
                        }
                        else{
                            noOpenAccessFound(page: page, doi: doi, year: year)
                        }
                    }
                    else{
                        noOpenAccessFound(page: page, doi: doi, year: year)
                    }
                }
                else{
                    noOpenAccessFound(page: page, doi: doi, year: year)
                }
            }
        }
        catch let jsonError{
            NSLog("\(jsonError)")
            noOpenAccessFound(page: page, doi: doi, year: year)
            return
        }
    }
    
    func noOpenAccessFound(page: SFSafariPage, doi: String, year: Int){
        let date = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: date)
        let fiveYearsAgo = currentYear - 6
        let oabRequestSetting = preferences.getValue(key: "oabrequest")
        let illRequestSettingTmp = preferences.getValue(key: "ill")
        var illRequestSetting = "n";
        let illUrl = preferences.getStringValue(key: "illUrl")
        if(illRequestSettingTmp){
            illRequestSetting = "y";
        }
        self.toolbarAction(imgName: "oahelper_black.pdf")
        let illLabel = NSLocalizedString("Ask your Library!", comment: "Ask your library");
        if(oabRequestSetting){
            
            // oab: y = yes, e = error getting data, o = older than 5 years ago
            
            if(year == 0 || year > fiveYearsAgo){
                page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "y", "oab" : "y", "doistring" : doi, "ill" : illRequestSetting, "illUrl" : illUrl, "illLabel" : illLabel])
                self.findOpenCitations(doi: doi, page: page)
            }
            else if(year == 1){
                page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "n", "oab" : "e", "doistring" : doi, "ill" : illRequestSetting, "illUrl" : illUrl, "illLabel" : illLabel])
                self.findOpenCitations(doi: doi, page: page)
            }
            else{
                page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "n", "oab" : "o", "doistring" : doi, "ill" : illRequestSetting, "illUrl" : illUrl, "illLabel" : illLabel])
            }
            
            
        }
        else{
            page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "n", "oab" : "n", "doistring" : doi, "ill" : illRequestSetting, "illUrl" : illUrl, "illLabel" : illLabel])
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
            self.toolbarAction(imgName: "oahelper_black_filled.pdf")
            self.updateBadge(text: "✔")
            let title = NSLocalizedString("You are at the Open Acccess Location!", comment: "used in JS confirm that you are on OA already")
            page.dispatchMessageToScript(withName: "onoa", userInfo: ["title" : title]);
        }
        
    }
    
    func runUrlCall(current: String, next: String, page: SFSafariPage) {
        if let url = URL(string: next){
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
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
                        self.toolbarAction(imgName: "oahelper_black_filled.pdf")
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
        else if (domain1 == "psycnet.apa.org" && domain2 == "doi.apa.org"){
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
        let ezproxyPrefix = self.preferences.getStringValue(key: "ezproxyPrefix")
        var msg = ""
        var type = ""
        if(id == "oahdoire_0") {
            msg = NSLocalizedString("Open Access Helper could not find a legal open-access version of this article.", comment: "will show in JS Alert, when there was a doi, but no oadoi url")
            type = "alert"
        }
        else if(id == "oahdoire_1" && ezproxyPrefix == ""){
            msg = NSLocalizedString("Open Access Helper is inactive on this page, as we could not identify a DOI\n\nClick OK to learn more about this app\nClick Cancel to dismiss this message", comment: "will show in JS Alert, when there no doi = inactive state")
            type = "confirm"
        }
        else if(id == "oahdoire_1" && ezproxyPrefix != ""){
            updateEzProxyCount()
            msg = "proxy"
            type = "proxy"
        }
        if(msg != ""){
            page.dispatchMessageToScript(withName: "showAlert", userInfo: ["msg" : msg, "type" : type, "ezproxy" : ezproxyPrefix]);
        }
    }
    
    func updateCount(){
        preferences.incrementIntVal(key: "oaFoundCount")
    }
    
    func updateOASearchCount(){
        preferences.incrementIntVal(key: "oaSearchCount")
    }
    
    func updateEzProxyCount(){
        preferences.incrementIntVal(key: "ezProxyCount")
    }
    
    
    func getOpenAccessVersion(data: Unpaywall) -> String{
        if let version = data.best_oa_location?.version{
            
            switch version{
            case "submittedVersion":
                return NSLocalizedString("Submitted Version", comment: "submittedVersion")
            case "acceptedVersion":
                return NSLocalizedString("Accepted Version", comment: "acceptedVersion")
            case "publishedVersion":
                return NSLocalizedString("Published Version", comment: "publishedVersion")
            default:
                return ""
            }
            
        }
        return ""
    }
    
    func getAPIKeyFromPlist(type: String) -> String{
        //we are going to read the api key for coar.ac.uk from apikey.plist
        //this file isn't the github bundle and as such you'll need to create it yourself, it is a simple Object
        // core : String = API Key from core.ac.uk
        var nsDictionary: NSDictionary?
        if let path = Bundle.main.path(forResource: "apikey", ofType: "plist") {
            nsDictionary = NSDictionary(contentsOfFile: path)
        }
        if let key = nsDictionary?[type]{
            return "\(key)"
        }
        return ""
    }
    
    //MARK: CORE RECOMMENDATION STUFF
    
    func requestRecommendation(userInfo: [String : Any]?, page: SFSafariPage){
        
        guard let doi = userInfo!["doi"] as? String else{
            page.dispatchMessageToScript(withName: "recomResults", userInfo: ["action" : "dismiss", "detail" : "no doi"])
            return
        }
        guard let docTitle = userInfo!["docTitle"] as? String else{
            page.dispatchMessageToScript(withName: "recomResults", userInfo: ["action" : "dismiss", "detail" : "no docTitle"])
            return
        }
        guard let currentUrl = userInfo!["currentUrl"] as? String else{
            page.dispatchMessageToScript(withName: "recomResults", userInfo: ["action" : "dismiss", "detail" : "no currentUrl"])
            return
        }
        var abstract = ""
        if let abs = userInfo?["abstract"] as? String{
            abstract = abs
        }
        
        let recommendationObject = CoreRequestObject()
        recommendationObject.title = docTitle
        recommendationObject.doi = doi
        recommendationObject.aabstract = abstract
        recommendationObject.referer = currentUrl
        
        self.askForRecommendation(metaData: recommendationObject) { (res) in
            switch res{
            case .success(let coreRecommends):
                // let's check if there are recommendations and then display

                if(coreRecommends.count > 0){
                    let encoder = JSONEncoder()
                    if let jsonData = try? encoder.encode(coreRecommends) {
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            let infoString = NSLocalizedString("We found a short list of fresh papers similar to the one you are currently browsing. We hope you'll like them!", comment: "to be shown in JavaScript Popover")
                            page.dispatchMessageToScript(withName: "recomResults", userInfo: ["action" : "show", "data" : jsonString, "infoString": infoString])
                        }
                        else{
                            page.dispatchMessageToScript(withName: "recomResults", userInfo: ["action" : "dismiss", "detail": "unable to create jsonString"])
                        }
                    }
                    else{
                        page.dispatchMessageToScript(withName: "recomResults", userInfo: ["action" : "dismiss", "detail" : "unable to jsonEncode"])
                    }

                }
                else{
                    // there was nothing
                    page.dispatchMessageToScript(withName: "recomResults", userInfo: ["action" : "dismiss", "detail" : "data count == 0"])
                }
                
            case .failure(let error):
                //I hate my life right now
                print("===== core recommend: there was an error: \(error)")
                page.dispatchMessageToScript(withName: "recomResults", userInfo: ["action" : "dismiss", "detail" : "failure from data task"])
            }
        }
        
    }
    
    func askForRecommendation(metaData : CoreRequestObject, completion: @escaping (Result<[CoreRecommender], Error>) -> ()){
        let apiKey = self.getAPIKeyFromPlist(type: "core")
        if (apiKey == "") {
            //print("no API Key")
            completion(.failure(NSError(domain: "", code: 441, userInfo: ["description" : "no APIKey Present"])))
            return
        }
        //make request JSON
        let json: [String: Any] = ["limit": "3",
                                   "identifier": "\(metaData.doi)",
                                   "abstract": "\(metaData.aabstract)",
                                   "authors": "\(metaData.author)",
                                   "title": "\(metaData.title)",
                                   "exclude": ["fullText"]
                                    ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        //prepare API call
        let jsonUrlString = "https://api.core.ac.uk/v3/recommend"
        guard let url = URL(string: jsonUrlString) else {
            completion(.failure(NSError(domain: "", code: 443, userInfo: ["description" : "could not create URL"])))
            return
        }
        
        //setup POST REQUEST
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let urlconfig = URLSessionConfiguration.default
        urlconfig.timeoutIntervalForRequest = 31
        urlconfig.timeoutIntervalForResource = 31
        
        let session = URLSession(configuration: urlconfig, delegate: self as? URLSessionDelegate, delegateQueue: nil)
        
        let task = session.dataTask(with: request) {(data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                completion(.failure(error))
                print(error)
            }
            if let data = data {
                //this worked just fine
                do {
                    let recommendations = try JSONDecoder().decode([CoreRecommender].self, from: data)
                    completion(.success(recommendations))
                }
                catch let jsonError{
                    //print(data)
                    //print("json decode error", jsonError)
                    print("JSON String: \(String(data: data, encoding: .utf8) ?? "JSON ERROR COULD NOT PRINT")")
                    completion(.failure(jsonError))
                }
            }
            else{
                //another error
                completion(.failure(NSError(domain: "", code: 440, userInfo: ["description" : "failed to get data"])))
                return
            }
            
        }
        task.resume()
        
    }
    
    //MARK: OpenCitations related
    
    func findOpenCitations(doi: String, page: SFSafariPage){
        
        //check if OpenCitations desired
        if(!preferences.getValue(key: "opencitations")){
            //user does not require OpenCitations
            return
        }
        
        //execute
        findCitations(doi: doi) { (res) in
            switch res{
            case .success(let openCitation):
                if let count = Int(openCitation.count) {
                    if(count > 0){
                        page.dispatchMessageToScript(withName: "opencitation_count", userInfo: ["citation_count" : count, "doi" : doi])
                    }
                }
                
            case .failure(let error):
                //I hate my life right now
                print("openCitation: there was an error: \(error)")
            }
        }
    }
    
    func findCitations(doi : String, completion: @escaping (Result<OpenCitationStruct, Error>) -> ()){
        let urlString = "https://opencitations.net/index/api/v1/citation-count/\(doi)"
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            if let error = error{
                //we got an error, let's tell the user
                print("error")
                completion(.failure(error))
                print(error)
            }
            if let data = data {
                //this worked just fine
                do {
                    let openCitations = try JSONDecoder().decode([OpenCitationStruct].self, from: data)
                    if(openCitations.count > 0){
                        //print("data received \(openCitations.first!.count)")
                        completion(.success(openCitations.first!))
                    }
                    else{
                        //print("Successful decode with 0 elements, should be impossible to be honest")
                        completion(.failure(NSError(domain: "", code: 441, userInfo: ["description" : "failed to get any objects"])))
                    }
                    
                }
                catch let jsonError{
                    //print("JSON String: \(String(data: data, encoding: .utf8) ?? "JSON ERROR COULD NOT PRINT")")
                    completion(.failure(jsonError))
                }
            }
            else{
                //another error
                //print("failed to get data")
                completion(.failure(NSError(domain: "", code: 440, userInfo: ["description" : "failed to get data"])))
                return
            }
            
        }.resume()
        
    }
    
    func updateSettingsFromServer() {
        let compareTime = "\(NSDate().timeIntervalSince1970 - 7*24*60*60)"
        let lastUpdateTime = self.preferences.getStringValue(key: "lastUpdate")
        let instituteId = self.preferences.getStringValue(key: "instituteId")
        
        if (compareTime < lastUpdateTime) {
            return
        }
        
        if (instituteId == ""){
            return
        }
        
        let proxyFind = ProxyFind()
        print("\(instituteId)")
        proxyFind.askForProxy(domain: "\(instituteId)", searchType: "id") { (res) in
            switch (res) {
            case .success(let proxyList):
                if(proxyList.count == 1){
                    proxyFind.processProxyList(proxyList: proxyList) { (res1) in
                        switch res1 {
                        case .success(_):
                            print("Successfully processed Proxy List")
                        case .failure(_):
                            print("Failed processed Proxy List")
                        }
                    }
                }
            case .failure(_):
                print("Failed to get proxy list")
            }
        }

    }
    
}

