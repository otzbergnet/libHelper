//
//  BookMarkTableView.swift
//  Open Access Helper
//
//  Created by Claus Wolf on 10.03.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Cocoa

class BookMarkObject {
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
        
        let directoryItem = BookMarkObject()
        directoryItem.title = "test"
        directoryItem.url = "https://www.test.com"
        directoryItem.date = Date()
        directoryItems.append(directoryItem)
        
        self.data.fetchBookMarks(){ bookmarks in
            self.directoryItems = bookmarks
            self.reloadFileList()
        }
        
    }

    func reloadFileList() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    @objc func tableViewDoubleClick(_ sender:AnyObject) {
        // 1
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
        
        // 1
        let item = directoryItems[row]
        print(item)
        
        // 2
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
        
        // 3
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
    
}
