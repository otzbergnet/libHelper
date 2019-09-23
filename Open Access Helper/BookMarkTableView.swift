//
//  BookMarkTableView.swift
//  Open Access Helper
//
//  Created by Claus Wolf on 10.03.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Cocoa

class BookMarkObject:NSObject {
    var date : Date = Date()
    var doi : String = ""
    var pdf : String = ""
    var synced : Bool = false
    var del : Bool = false          //using del rather than deleted, as deleted got me an error
    var title : String = ""
    var url : String = ""
    var id : String = ""
}

class BookMarkTableView: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    var directoryItems = [BookMarkObject]()
    
    let data = DataSync()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick(_:))
        tableView.action = #selector(onItemClicked)
        
        let descriptorName = NSSortDescriptor(key: "title", ascending: true)
        let descriptorDate = NSSortDescriptor(key: "date", ascending: true)
        let descriptorUrl = NSSortDescriptor(key: "url", ascending: true)
        
        tableView.tableColumns[0].sortDescriptorPrototype = descriptorDate
        tableView.tableColumns[1].sortDescriptorPrototype = descriptorName
        tableView.tableColumns[2].sortDescriptorPrototype = descriptorUrl
        
        let directoryItem = BookMarkObject()
        directoryItem.title = "Open Access Helper"
        directoryItem.url = "https://www.otzberg.net/oahelper"
        directoryItem.date = Date()
        directoryItems.append(directoryItem)
        
        self.data.fetchBookMarks(){ bookmarks in
            self.directoryItems = bookmarks
            self.reloadFileList()
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open", action: #selector(tableViewOpenItemClicked(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Delete", action: #selector(tableViewDeleteItemClicked(_:)), keyEquivalent: ""))
        tableView.menu = menu
        
    }
    
    deinit {
        self.view.window?.unbind(NSBindingName(rawValue: #keyPath(touchBar)))
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        if #available(OSX 10.12.1, *) {
            self.view.window?.unbind(NSBindingName(rawValue: #keyPath(touchBar))) // unbind first
            self.view.window?.bind(NSBindingName(rawValue: #keyPath(touchBar)), to: self, withKeyPath: #keyPath(touchBar), options: nil)
        }
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        
        guard let sortDescriptor = tableView.sortDescriptors.first else {
            return
        }
        if(sortDescriptor.key == "title"){
            if(sortDescriptor.ascending){
                self.directoryItems = self.directoryItems.sorted { $0.title < $1.title }
            }
            else{
                self.directoryItems = self.directoryItems.sorted { $0.title > $1.title }
            }
            reloadFileList()
        }
        else if(sortDescriptor.key == "url"){
            if(sortDescriptor.ascending){
                self.directoryItems = self.directoryItems.sorted { $0.url < $1.url}
            }
            else{
                self.directoryItems = self.directoryItems.sorted { $0.url > $1.url }
            }
            reloadFileList()
        }
        else if(sortDescriptor.key == "date"){
            if(sortDescriptor.ascending){
                self.directoryItems = self.directoryItems.sorted { $0.date < $1.date }
            }
            else{
                self.directoryItems = self.directoryItems.sorted { $0.date > $1.date }
            }
            reloadFileList()
        }
    }
    
    @objc private func onItemClicked() {
        //print("row \(tableView.clickedRow), col \(tableView.clickedColumn) clicked")
        self.touchBar = nil
    }
    
    
    func reloadFileList() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @objc private func tableViewOpenItemClicked(_ sender: AnyObject) {
        //print("right clicked")
        if(tableView.clickedRow < 0){
            return
        }
        let item = self.directoryItems[tableView.clickedRow]
        
        if let url = URL(string: item.url),
            NSWorkspace.shared.open(url) {
        }
        else{
            return
        }
    }
    
    @IBAction func delete(_ sender: AnyObject){
        deleteItem(sender)
    }
    
    @objc private func tableViewDeleteItemClicked(_ sender: AnyObject) {
        deleteItem(sender)
    }
    
    private func deleteItem(_ sender: AnyObject){
        var row = 0
        if(tableView.clickedRow < 0 && tableView.selectedRow < 0){
            return
        }
        else if(tableView.clickedRow > 0){
            row = tableView.clickedRow
        }
        else if(tableView.selectedRow > 0){
            row = tableView.selectedRow
        }
        let item = self.directoryItems[row]
        
        self.data.deleteBookmark(recordName: item.id){ (testValue) in
            if testValue {
                self.data.fetchBookMarks(){ bookmarks in
                    self.directoryItems = bookmarks
                    self.reloadFileList()
                }
            }
            else{
                self.data.fetchBookMarks(){ bookmarks in
                    self.directoryItems = bookmarks
                    self.reloadFileList()
                }
            }
        }
    }
    
    @objc func tableViewDoubleClick(_ sender:AnyObject) {
        if tableView.selectedRow < 0{
            return
        }
        let item = self.directoryItems[tableView.selectedRow]
        
        if let url = URL(string: item.url),
            NSWorkspace.shared.open(url) {
        }
        else{
            return
        }
    }
    
    
}


extension BookMarkTableView: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return directoryItems.count
    }
}

extension BookMarkTableView: NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let dateCell = "DateCellId"
        static let titleCell = "TitleCellId"
        static let urlCell = "UrlCellId"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var text: String = ""
        var cellIdentifier: String = ""
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        let item = directoryItems[row]
        
        if tableColumn == tableView.tableColumns[0] {
            text = dateFormatter.string(from: item.date)
            cellIdentifier = CellIdentifiers.dateCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = item.title
            cellIdentifier = CellIdentifiers.titleCell
        } else if tableColumn == tableView.tableColumns[2] {
            text = item.url
            cellIdentifier = CellIdentifiers.urlCell
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
    
}


@available(OSX 10.12.1, *)
extension BookMarkTableView: NSTouchBarDelegate {
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .bar4
        if tableView.selectedRow < 0{
            touchBar.defaultItemIdentifiers = [.label5]
            touchBar.customizationAllowedItemIdentifiers = [.label5]
        }
        else{
            touchBar.defaultItemIdentifiers = [.label4, .openBookmark, .deleteBookmark]
            touchBar.customizationAllowedItemIdentifiers = [.label4, .openBookmark, .deleteBookmark]
        }
        
        return touchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItem.Identifier.label4:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            customViewItem.view = NSTextField(labelWithString: "Bookmarks: ")
            return customViewItem
        case NSTouchBarItem.Identifier.label5:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            let labelString = NSLocalizedString("Bookmarks: Select a row to see options", comment: "")
            customViewItem.view = NSTextField(labelWithString: labelString)
            return customViewItem
        case NSTouchBarItem.Identifier.openBookmark:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let labelString = NSLocalizedString("Open Bookmark", comment: "")
            let button = NSButton(title: labelString, target: self, action: #selector(tableViewDoubleClick(_:)))
            button.bezelColor = NSColor.systemBlue
            saveItem.view = button
            return saveItem
        case NSTouchBarItem.Identifier.deleteBookmark:
            let saveItem = NSCustomTouchBarItem(identifier: identifier)
            let labelString = NSLocalizedString("Delete Bookmark", comment: "")
            let button = NSButton(title: labelString, target: self, action: #selector(delete(_:)))
            button.bezelColor = NSColor.systemRed
            saveItem.view = button
            return saveItem
        default:
            return nil
        }
    }
}
