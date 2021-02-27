//
//  SafariExtensionViewController.swift
//  libHelper Safari
//
//  Created by Claus Wolf on 28.10.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import SafariServices
import WebKit

class SafariExtensionViewController: SFSafariExtensionViewController, WKUIDelegate{
    
    @IBOutlet weak var webView: WKWebView!
    let preferences = Preferences()
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:310, height:420)
        return shared
    }()
    
    func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }
    
    override func viewDidLoad() {
        webView.uiDelegate = self
    }

    override func viewWillAppear() {
        getCurrentState()
    }
    
    func createPopover(popupAnswer: PopupAnswer){
        var buttonCount = 0;
        var illButtonCount = 0;
        var oabutton = ""
        var citationbutton = ""
        var proxybutton = ""
        var addonbutton = ""
        
        if (popupAnswer.oaurl != "" && popupAnswer.oastatus != "") {
          if (popupAnswer.oaurl.contains("https://openaccessbutton.org/request?")) {
            oabutton = "We didn't find an Open Access copy :(<br><a class=\"button\" id=\"oabuttonrequest\" href=\"\(popupAnswer.oaurl)\" target=\"_blank\">\(popupAnswer.oastatus)</a>"
            buttonCount += 1;
          }
          else if(popupAnswer.isIll == "ill") {
            oabutton = "We didn't find an Open Access copy :(<br><a class=\"button\" id=\"oabuttonrequest\" href=\"\(popupAnswer.oaurl)\" target=\"_blank\">\(popupAnswer.oastatus)</a>"
            buttonCount += 1;
            illButtonCount += 1;
          }
          else {
            oabutton = "We found an Open Access copy!<br><a class=\"button\" id=\"oabutton\" href=\"\(popupAnswer.oaurl)\" target=\"_blank\">\(popupAnswer.oastatus)</a>"
            buttonCount += 1;
          }
        }
        if (popupAnswer.citationCount > 0) {
            citationbutton = "See who cited this paper:<br><a class=\"button\" id=\"citationbutton\" href=\"https://www.oahelper.org/opencitations/?doi=\(popupAnswer.doi)\" target=\"_blank\">Times Cited: \(popupAnswer.citationCount)</a>"
          buttonCount += 1;
        }

        let ezproxyPrefix = self.preferences.getStringValue(key: "ezproxyPrefix")
        let instituteName = self.preferences.getStringValue(key: "instituteName")
        

        if (ezproxyPrefix != "" && popupAnswer.currentUrl != "" && !onProxiedDomain(ezproxyPrefix: ezproxyPrefix, currentUrl: popupAnswer.currentUrl)) {
            let currentUrl = URL(string: popupAnswer.currentUrl)
            if let domain = currentUrl?.host{
                var urltoproxy = domain;
                if (domain.count > 25) {
                  urltoproxy = "\(domain.prefix(25))&hellip;"
                }
                let proxyUrl = "\(ezproxyPrefix)\(popupAnswer.currentUrl)"
                proxybutton = "Your <em>\(instituteName)</em> Access:<br><a class=\"button\" id=\"ezproxybutton\" href=\"\(proxyUrl)\" target=\"_blank\">\(urltoproxy)</a>"
                buttonCount += 1;
            }
        }

        let ill = preferences.getValue(key: "ill")
        let illUrl = preferences.getStringValue(key: "illUrl")
        
        if(ill && popupAnswer.doi != "" && popupAnswer.doi != "" && illButtonCount == 0){
            let illRequestUrl = "\(illUrl)\(popupAnswer.doi)"
            let illLabel = "Ask your Library"

          if(buttonCount < 3){
            //we will simply add a new button
            addonbutton = "Still no access?<br><a class=\"button\" id=\"oabuttonrequest\" href=\"\(illRequestUrl)\" target=\"_blank\">\(illLabel)</a>"
          }
          else{
            addonbutton = "Still no access? <a class=\"button\" id=\"oabuttonrequestlink\" href=\"\(illRequestUrl)\" target=\"_blank\">\(illLabel)</a>"
          }
        }

        let buttons = "\(oabutton)\(citationbutton)\(proxybutton)\(addonbutton)"
        let popupHtml = """
        <!DOCTYPE HTML>
            <html>
            <head>
                <meta charset="utf-8">
                <title>Open Access Helper Popover</title>
                <link rel="stylesheet" href="popup.css">
            </head>
            <body>
                <div id="header">
                    <a href="oahelper://settings/" id="configurationlink" target="_blank"><img src="gear.svg" id="oah_settings_icon" alt="settings icon" title="Configure the extension"></a>
                    <img src="oahelper_black.svg" id="oahelpericon">Open Access Helper
                </div>
                <div id="popupanswer">\(buttons)</div>
                <div id="footer"><a href="https://www.oahelper.org/support/" id="supportlink" target="_blank">Contact Support </a> | <a href="oahelper://settings/" id="configurationlink" target="_blank">Configuration</a><span id="hidebadgespan"> | <a href="oahelper://clearBadge/" id="hidebadges" target="_blank">Hide Badges</a></span></div>
            </body>
            </html>
        """
        webView.loadHTMLString(popupHtml, baseURL: Bundle.main.resourceURL)
    }
    
    func onProxiedDomain(ezproxyPrefix: String, currentUrl: String) -> Bool{
        let ezproxyUrl = URL(string: ezproxyPrefix)
        if let urlParts = ezproxyUrl?.host?.components(separatedBy: ".") {
            var newUrlParts = urlParts
            newUrlParts.removeFirst(1)
            let testUrl = newUrlParts.joined(separator: ".")
            if(currentUrl.contains(testUrl)){
                return true;
            }
        }
        return false
    }
    
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            let navRequest = "\(navigationAction.request)"
            switch navRequest {
            case "oahelper://settings/":
                self.dismissPopover()
                if let url = URL(string: "oahelper:settings"),
                   NSWorkspace.shared.open(url) {
                }
            case "oahelper://clearBadge/":
                sendHideBadgeRequest()
                self.dismissPopover()
            default:
                openExternalUrl(url: navRequest)
            }
            
            
        }
        return nil
    }
    
    func openExternalUrl(url: String) {
        guard let myUrl = URL(string: url) else { return  }
        SFSafariApplication.getActiveWindow { (activeWindow) in
            activeWindow?.openTab(with: myUrl, makeActiveIfPossible: true, completionHandler: {_ in
                self.dismissPopover()
            })
        }
    }
    
    func getCurrentState(){
        SFSafariApplication.getActiveWindow { (window) in
            window?.getActiveTab(completionHandler: { (activeTab) in
                activeTab?.getActivePage(completionHandler:  { (activePage) in
                    activePage?.getPropertiesWithCompletionHandler( { (properties) in
                        activePage?.dispatchMessageToScript(withName: "getCurrentState", userInfo: [:])
                    })
                })
            })
        }
    }
    
    func sendHideBadgeRequest(){
        SFSafariApplication.getActiveWindow { (window) in
            window?.getActiveTab(completionHandler: { (activeTab) in
                activeTab?.getActivePage(completionHandler:  { (activePage) in
                    activePage?.getPropertiesWithCompletionHandler( { (properties) in
                        activePage?.dispatchMessageToScript(withName: "hideBadge", userInfo: [:])
                    })
                })
            })
        }
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("didCommit")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("didFinish")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("didFail")
    }
}
