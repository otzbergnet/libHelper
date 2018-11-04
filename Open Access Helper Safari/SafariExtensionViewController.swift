//
//  SafariExtensionViewController.swift
//  libHelper Safari
//
//  Created by Claus Wolf on 28.10.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController{
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:320, height:240)
        return shared
    }()
    
    func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }
    

    
}
