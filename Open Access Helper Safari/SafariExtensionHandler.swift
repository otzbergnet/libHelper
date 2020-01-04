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
              page.dispatchMessageToScript(withName: "doCoreRecom", userInfo: ["doCoreRecom" : true])
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
            noOpenAccessFound(page: page, doi: "y", year: year)
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
            noOpenAccessFound(page: page, doi: "y", year: year)
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
                self.noOpenAccessFound(page: page, doi: "y", year: year)
            }
            if let data = data {
                self.handleOAButtonData(data: data, page: page, originUrl: originUrl, year: year)
            }
            else{
                NSLog("OAHELPER: OAB ERROR in dataTask / else")
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["oa_button_data" : "failed"])
                self.noOpenAccessFound(page: page, doi: "y", year: year)
                return
            }
            
        }
        
        task.resume()
    }

    func handleOAButtonData(data: Data, page: SFSafariPage, originUrl : String, year: Int){
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
                    }
                    else{
                        noOpenAccessFound(page: page, doi: "y", year: year)
                    }
                }
                else{
                    if let oabRequests = oaButtonData.data.requests {
                        if let requestId = oabRequests.first??.id {
                            self.checkOAButtonRequest(request: requestId, page: page, originUrl: originUrl, year: year)
                        }
                        else{
                            noOpenAccessFound(page: page, doi: "y", year: year)
                        }
                    }
                    else{
                        noOpenAccessFound(page: page, doi: "y", year: year)
                    }
                }
                
            }
            else {
                noOpenAccessFound(page: page, doi: "y", year: year)
                
            }
        }
        catch let jsonError{
            page.dispatchMessageToScript(withName: "printPls", userInfo: ["handleData_error" : "\(jsonError)"])
            noOpenAccessFound(page: page, doi: "y", year: year)
            
            return
        }
    }
    
    
    func checkOAButtonRequest(request: String, page: SFSafariPage, originUrl: String, year: Int) {
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
                self.noOpenAccessFound(page: page, doi: "y", year: year)
                
            }
            if let data = data {
                self.handleOABRequestData(data: data, page: page, originUrl: originUrl, year: year)
            }
            else{
                page.dispatchMessageToScript(withName: "printPls", userInfo: ["oa_button_data" : "failed"])
                self.noOpenAccessFound(page: page, doi: "y", year: year)
                return
            }
            
        }
        
        task.resume()
    }
    
    func handleOABRequestData(data: Data, page: SFSafariPage, originUrl : String, year: Int){
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
                                noOpenAccessFound(page: page, doi: "y", year: year)
                            }
                        }
                        else{
                            noOpenAccessFound(page: page, doi: "y", year: year)
                        }
                    }
                    else{
                        noOpenAccessFound(page: page, doi: "y", year: year)
                    }
                }
                else{
                    noOpenAccessFound(page: page, doi: "y", year: year)
                }
            }
        }
        catch let jsonError{
            NSLog(jsonError as! String)
            noOpenAccessFound(page: page, doi: "y", year: year)
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
                page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "y", "oab" : "y"])
            }
            else if(year == 1){
               page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "n", "oab" : "e"])
            }
            else{
                page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "n", "oab" : "o"])
            }
            
        }
        else{
            page.dispatchMessageToScript(withName: "notoadoi", userInfo: ["doi" : "n", "oab" : "n"])
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


struct Coredata : Decodable{
    let fullTextLink : String?
    let source : String?
}


struct OaButton : Decodable{
    let data : OAData
}

struct OAData : Decodable{
    let availability : [OAAvailability?]?
    let requests : [OARequests?]?
}

struct OAAvailability : Decodable{
    let type : String?
    let url : String?
}

struct OARequests : Decodable {
    let type : String?
    let id : String?
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case id = "_id"
    }
}

struct OARequestData : Decodable{
    let data : OARequestObject
}

struct OARequestObject : Decodable{
    let status : String?
    let received : OAReceivedObject?
}

struct OAReceivedObject : Decodable{
    let url : String?
}
