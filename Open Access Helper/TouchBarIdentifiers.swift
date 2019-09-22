//
//  TouchBarIdentifiers.swift
//  Open Access Helper
//
//  Created by Claus Wolf on 22.09.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import AppKit

extension NSTouchBarItem.Identifier {
    static let label1 = NSTouchBarItem.Identifier("net.otzberg.libHelper.viewController.label1")
    static let openPreferences = NSTouchBarItem.Identifier("net.otzberg.libHelper.viewController.openPreferences")
    static let openExample = NSTouchBarItem.Identifier("net.otzberg.libHelper.viewController.openExample")
    static let label2 = NSTouchBarItem.Identifier("net.otzberg.libHelper.AboutController.label2")
    static let contact = NSTouchBarItem.Identifier("net.otzberg.libHelper.AboutController.contact")
    static let unpaywall = NSTouchBarItem.Identifier("net.otzberg.libHelper.AboutController.unpaywall")
    static let core = NSTouchBarItem.Identifier("net.otzberg.libHelper.AboutController.core")
    static let oab = NSTouchBarItem.Identifier("net.otzberg.libHelper.AboutController.oab")
    static let label3 = NSTouchBarItem.Identifier("net.otzberg.libHelper.SettingsController.label3")
    static let moreInfo = NSTouchBarItem.Identifier("net.otzberg.libHelper.SettingsController.moreInfo")
    static let noneSelected = NSTouchBarItem.Identifier("net.otzberg.libHelper.SettingsController.noneSelected")
    static let recommendedSelected = NSTouchBarItem.Identifier("net.otzberg.libHelper.SettingsController.recommendedSelected")
}


extension NSTouchBar.CustomizationIdentifier {
    static let bar1 = NSTouchBar.CustomizationIdentifier("net.otzberg.libHelper.ViewController.bar1")
    static let bar2 = NSTouchBar.CustomizationIdentifier("net.otzberg.libHelper.AboutController.bar2")
    static let bar3 = NSTouchBar.CustomizationIdentifier("net.otzberg.libHelper.AboutController.bar3")
}
