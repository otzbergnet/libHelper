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
    
    let preferences = Preferences()
    let stats = StatisticSubmit()
    
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
            toolbarAction(imgName: "oa_100.pdf")
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
        else if messageName == "searchOA2"{
            searchOA(userInfo: (userInfo)!, type: "oasearch2")
        }
        else if messageName == "searchOA3"{
            searchOA(userInfo: (userInfo)!, type: "oasearch3")
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
                self.toolbarAction(imgName: "oa_100a.pdf")
            }
            else{
                self.toolbarAction(imgName: "oa_100.pdf")
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
        
        //        page.getPropertiesWithCompletionHandler { properties in
        //            NSLog("The extension received a message (\(messageName)) from a script injected into (\(String(describing: properties?.url))) with userInfo (\(userInfo ?? [:]))")
        //        }
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
            if(command == "oasearch" && selectedText.count > 0){
                myContextLabel = String(format: NSLocalizedString("base-search.net search for: \"%@\"", comment: "changes Context Label"), String(mySubstring))
            }
            else if(command == "oasearch" && selectedText.count == 0){
                myContextLabel = String(format: NSLocalizedString("Visit base-search.net", comment: "changes Context Label, base-search-net"), String(mySubstring))
            }
            else if(command == "oasearch2" && selectedText.count > 0){
                myContextLabel = String(format: NSLocalizedString("core.ac.uk search for: \"%@\"", comment: "changes Context Label"), String(mySubstring))
            }
            else if(command == "oasearch2" && selectedText.count == 0){
                myContextLabel = String(format: NSLocalizedString("Visit core.ac.uk", comment: "changes Context Label"), String(mySubstring))
            }
            else if(command == "oasearch3" && selectedText.count > 0){
                myContextLabel = String(format: NSLocalizedString("gettheresearch.org search for: \"%@\"", comment: "changes Context Label"), String(mySubstring))
            }
            else if(command == "oasearch3" && selectedText.count == 0){
                myContextLabel = String(format: NSLocalizedString("Visit gettheresearch.org", comment: "changes Context Label"), String(mySubstring))
            }
            
            //validationHandler(false, myContextLabel)
            
            switch (command){
            case "oasearch":
                if(preferences.getValue(key: "basehs")){
                    validationHandler(false, myContextLabel)
                }
                else{
                    validationHandler(true, myContextLabel)
                }
            case "oasearch2":
                if(preferences.getValue(key: "corehs")){
                    validationHandler(false, myContextLabel)
                }
                else{
                    validationHandler(true, myContextLabel)
                }
            case "oasearch3":
                if(preferences.getValue(key: "gettheresearchhs")){
                    validationHandler(false, myContextLabel)
                }
                else{
                    validationHandler(true, myContextLabel)
                }
            default:
                NSLog("wbm_log: apparently we found a new command that we didn't code for. bummer...")
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
        
        //default to always return something
        var myurl = "https://www.base-search.net/Search/Results?lookfor=%22\(searchTerm!)%22&name=&oaboost=1&newsearch=1&l=en"
        
        if(command == "oasearch" && count > 0){
            myurl = "https://www.base-search.net/Search/Results?lookfor=%22\(searchTerm!)%22&name=&oaboost=1&newsearch=1&l=en"
        }
        else if(command == "oasearch" && count == 0){
            myurl = "https://www.base-search.net/"
        }
        else if(command == "oasearch2" && count > 0){
            myurl = "https://core.ac.uk/search?q=%22\(searchTerm!)%22"
        }
        else if(command == "oasearch2" && count == 0){
            myurl = "https://core.ac.uk/"
        }
        else if(command == "oasearch3" && count > 0){
            myurl = "https://gettheresearch.org/search?q=\(searchTerm!)"
        }
        else if(command == "oasearch3" && count == 0){
            myurl = "https://gettheresearch.org"
        }
        
        return myurl
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
        window.getActiveTab { (activeTab) in
            activeTab?.getActivePage(completionHandler:  { (activePage) in
                activePage?.dispatchMessageToScript(withName: "tabevaluate", userInfo: nil);
            })
        }
        self.toolbarAction(imgName: "oa_100.pdf")
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
    
    func checkUnpaywall(doi: String, page: SFSafariPage, originUrl: String) {
        self.stats.submitStats(force: false)
        toolbarAction(imgName: "oa_100a.pdf")
        let jsonUrlString = "https://api.unpaywall.org/v2/\(doi)?email=oahelper@otzberg.net"
        let url = URL(string: jsonUrlString)
        
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                self.toolbarAction(imgName: "oa_100.pdf")
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["unpaywall_error" : error.localizedDescription])
                self.checkCore(doi: doi, page: page, originUrl: originUrl, year: 1)
            }
            if let data = data {
                self.handleData(data: data, page: page, doi: doi, originUrl: originUrl)
            }
            else{
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["unpaywall_data" : "failed"])
                self.toolbarAction(imgName: "oa_100.pdf")
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
                    toolbarAction(imgName: "oa_100a.pdf")
                    updateBadge(text: "!")
                    updateCount()
                    let oaVersion = self.getOpenAccessVersion(data: oaData)
                    let title = NSLocalizedString("Open Access Version Found from unpaywall.org! ", comment: "used in JS injection to indicate OA found")
                    page.dispatchMessageToScript(withName: "oafound", userInfo: [ "url" : "\(boa.url)", "title" : title, "source" : "unpaywall.org", "version" : "\(oaVersion)"])
                    self.findOpenCitations(doi: doi, page: page)
                }
                else{
                    toolbarAction(imgName: "oa_100.pdf")
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
                toolbarAction(imgName: "oa_100.pdf")
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
            toolbarAction(imgName: "oa_100.pdf")
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
        
        toolbarAction(imgName: "oa_100a.pdf")
        let apiKey = self.getAPIKeyFromPlist(type: "apikey")
        let jsonUrlString = "https://api.core.ac.uk/discovery/discover?doi=\(doi)&apiKey=\(apiKey)"
        let url = URL(string: jsonUrlString)
        
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                self.toolbarAction(imgName: "oa_100.pdf")
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["core.ac.uk_error" : error.localizedDescription])
                self.checkOAButton(doi: doi, page: page, originUrl: originUrl, year: 1)
            }
            if let data = data {
                self.handleCoreData(data: data, doi: doi, originUrl: originUrl, page: page, year: year)
                self.findOpenCitations(doi: doi, page: page)
            }
            else{
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["core.ac.uk_data" : "failed"])
                self.toolbarAction(imgName: "oa_100.pdf")
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
            if let boa = coreData.fullTextLink {
                if (boa != "") {
                    toolbarAction(imgName: "oa_100a.pdf")
                    updateBadge(text: "!")
                    updateCount()
                    let title = NSLocalizedString("Open Access Version Found from core.ac.uk! ", comment: "used in JS injection to indicate OA found")
                    page.dispatchMessageToScript(withName: "oafound", userInfo: [ "url" : "\(boa)", "title" : title, "source" : "core.ac.uk", "version" : ""])
                }
                else{
                    toolbarAction(imgName: "oa_100.pdf")
                    //page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "y"])
                    self.checkOAButton(doi: doi, page: page, originUrl: originUrl, year: year)
                }
            }
            else {
                toolbarAction(imgName: "oa_100.pdf")
                //page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "y"])
                self.checkOAButton(doi: doi, page: page, originUrl: originUrl, year: year)
            }
            
            
        }
        catch let jsonError{
            NSLog("\(jsonError)")
            //page.dispatchMessageToScript(withName: "printPls", userInfo: ["handleData_error" : "\(jsonError)"])
            toolbarAction(imgName: "oa_100.pdf")
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
        toolbarAction(imgName: "oa_100a.pdf")
        let apiKey = self.getAPIKeyFromPlist(type: "oabutton")
        if(apiKey == ""){
            self.toolbarAction(imgName: "oa_100.pdf")
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
                        toolbarAction(imgName: "oa_100a.pdf")
                        updateBadge(text: "!")
                        updateCount()
                        let title = NSLocalizedString("Open Access Version Found from Open Access Button ", comment: "used in JS injection to indicate OA found")
                        page.dispatchMessageToScript(withName: "oafound", userInfo: [ "url" : "\(targetUrl)", "title" : title, "source" : "Open Access Button", "version" : ""])
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
        toolbarAction(imgName: "oa_100a.pdf")
        let apiKey = self.getAPIKeyFromPlist(type: "oabutton")
        if(apiKey == ""){
            self.toolbarAction(imgName: "oa_100.pdf")
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
                                toolbarAction(imgName: "oa_100a.pdf")
                                updateBadge(text: "!")
                                updateCount()
                                let title = NSLocalizedString("Open Access Version Found from Open Access Button ", comment: "used in JS injection to indicate OA found")
                                page.dispatchMessageToScript(withName: "oafound", userInfo: [ "url" : "\(url)", "title" : title, "source" : "Open Access Button", "version" : ""])
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
        self.toolbarAction(imgName: "oa_100.pdf")
        if(oabRequestSetting){
            
            // oab: y = yes, e = error getting data, o = older than 5 years ago
            
            if(year == 0 || year > fiveYearsAgo){
                page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "y", "oab" : "y", "doistring" : doi])
                self.findOpenCitations(doi: doi, page: page)
            }
            else if(year == 1){
                page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "n", "oab" : "e", "doistring" : doi])
                self.findOpenCitations(doi: doi, page: page)
            }
            else{
                page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "n", "oab" : "o", "doistring" : doi])
            }
            
            
        }
        else{
            page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "n", "oab" : "n", "doistring" : doi])
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
                
                if(coreRecommends.data.count > 0){
                    let encoder = JSONEncoder()
                    if let jsonData = try? encoder.encode(coreRecommends.data) {
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
    
    func askForRecommendation(metaData : CoreRequestObject, completion: @escaping (Result<CoreRecommender, Error>) -> ()){
        let apiKey = self.getAPIKeyFromPlist(type: "coreRecommender")
        let apiEndPoint = self.getAPIKeyFromPlist(type: "coreRecommenderUrl")
        if (apiKey == "") {
            //print("no API Key")
            completion(.failure(NSError(domain: "", code: 441, userInfo: ["description" : "no APIKey Present"])))
            return
        }
        if(apiEndPoint == ""){
            //print("no API EndPoint")
            completion(.failure(NSError(domain: "", code: 442, userInfo: ["description" : "no API End Point Present"])))
            return
        }
        let jsonUrlString = apiEndPoint
        guard let url = URL(string: jsonUrlString) else {
            //print("could not create URL")
            completion(.failure(NSError(domain: "", code: 443, userInfo: ["description" : "could not create URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Token")
        request.httpMethod = "POST"
        
        let parameters: [String: Any] = [
            "title" : metaData.title,
            "aabstract" : metaData.aabstract,
            "author" : metaData.author,
            "referer" : metaData.referer,
            "url" : metaData.fulltextUrl,
            "doi" : metaData.doi,
            "origin" : "macOS"
        ]
        
        request.httpBody = parameters.percentEscaped().data(using: .utf8)
        let urlconfig = URLSessionConfiguration.default
        urlconfig.timeoutIntervalForRequest = 31
        urlconfig.timeoutIntervalForResource = 31
        
        let session = URLSession(configuration: urlconfig, delegate: self as? URLSessionDelegate, delegateQueue: nil)
        //print("start recommender task")
        let task = session.dataTask(with: request) {(data, response, error) in
            //print("The core recommender task took \(timer.stop()) seconds.")
            if let error = error{
                //we got an error, let's tell the user
                completion(.failure(error))
                print(error)
            }
            if let data = data {
                //this worked just fine
                //print("this worked fine")
                do {
                    print(data)
                    let recommendations = try JSONDecoder().decode(CoreRecommender.self, from: data)
                    completion(.success(recommendations))
                }
                catch let jsonError{
                    //print(data)
                    //print("json decode error", jsonError)
                    print("===== JSON String: \(String(data: data, encoding: .utf8) ?? "JSON ERROR")")
                    completion(.failure(jsonError))
                }
            }
            else{
                //another error
                print("another error")
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
        ///https://opencitations.net/index/api/v1/citation-count/10.1142/9789812701527_0009
        
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
                        print("data received \(openCitations.first!.count)")
                        completion(.success(openCitations.first!))
                    }
                    else{
                        print("Successful decode with 0 elements, should be impossible to be honest")
                        completion(.failure(NSError(domain: "", code: 441, userInfo: ["description" : "failed to get any objects"])))
                    }
                    
                }
                catch let jsonError{
                    print("JSON String: \(String(data: data, encoding: .utf8) ?? "JSON ERROR COULD NOT PRINT")")
                    completion(.failure(jsonError))
                }
            }
            else{
                //another error
                print("failed to get data")
                completion(.failure(NSError(domain: "", code: 440, userInfo: ["description" : "failed to get data"])))
                return
            }
            
        }.resume()
        
    }
    
}

