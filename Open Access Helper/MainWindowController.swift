//
//  MainWindowController.swift
//  Open Access Helper
//
//  Created by Claus Wolf on 22.09.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @available(OSX 10.12.1, *)
    override func makeTouchBar() -> NSTouchBar? {
        if let tabViewController = contentViewController?.children{
            for tabView in tabViewController{
                for child in tabView.children{
                    if let viewController = child as? ViewController{
                        return viewController.makeTouchBar()
                    }
                }
            }
        }
        return nil
    }
}
