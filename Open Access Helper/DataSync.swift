//
//  DataSync.swift
//  Open Access Helper
//
//  Created by Claus Wolf on 02.03.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Cocoa
import CloudKit

class DataSync: NSViewController {

    //CloudKit DB & ZONE
    let defaultContainer = CKContainer(identifier: "iCloud.net.otzberg.oaHelper")
    let privateDatabase = CKContainer(identifier: "iCloud.net.otzberg.oaHelper").privateCloudDatabase
    let customZone = CKRecordZone(zoneName: "bookMarkZone")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    
    public func fetchUserRecordID() {
        
        // Fetch User Record
        self.defaultContainer.fetchUserRecordID { (recordID, error) -> Void in
            if let responseError = error {
                print(responseError)
                _ = self.dialogOKCancel(messageText: NSLocalizedString("iCloud Error", comment:  "error message title"), text: NSLocalizedString("Please check that you are logged into iCloud", comment:  "error message shown, when iCloud not logged in"), cancel: false)
                
            } else if let userRecordID = recordID {
                DispatchQueue.main.sync {
                    self.fetchUserRecord(recordID: userRecordID)
                }
            }
        }
    }
    
    private func fetchUserRecord(recordID: CKRecord.ID) {
        
        // Fetch User Record
        self.privateDatabase.fetch(withRecordID: recordID) { (record, error) -> Void in
            if let responseError = error {
                print(responseError)
                _ = self.dialogOKCancel(messageText: NSLocalizedString("iCloud Error", comment:  ""), text: NSLocalizedString("Please check that you are logged into iCloud", comment:  ""), cancel: false)
                
            } else if record != nil {
                //self.fetchBookMarks()
            }
        }
    }
    
    public func fetchBookMarks(completion : @escaping (_ bookmarks : [BookMarkObject]) -> ()){
        
        var bookmarks = [BookMarkObject]()
        
        // Initialize Query
        let query = CKQuery(recordType: "Bookmarks", predicate: NSPredicate(value: true))
        
        // Configure Query
        //query.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
        
        // Perform Query
        self.privateDatabase.perform(query, inZoneWith: self.customZone.zoneID) { (records, error) in
            if let responseError = error{
                
                let e1 = error as! CKError
                if (e1.code == .notAuthenticated){
                    // this request requires an authenticated account
                    DispatchQueue.main.async {
                        _ = self.dialogOKCancel(messageText: NSLocalizedString("iCloud Error", comment:  "iCloud error - not authenticated"), text: NSLocalizedString("We are sorry, but it seems that you either do not have an iCloud account, or access is limited for Open Access Helper. Please check iCloud settings", comment:  ""), cancel: false)
                        
                    }
                }
                else if (e1.code == .networkFailure || e1.code == .networkUnavailable){
                    DispatchQueue.main.async {
                        _ = self.dialogOKCancel(messageText: NSLocalizedString("Connection Error", comment:  "iCloud internet connection"), text: NSLocalizedString("We are sorry, but there was a connection error. Please check your Internet Connection", comment:  ""), cancel: false)
                        
                    }
                }
                else if (e1.code == .zoneNotFound || e1.code == .userDeletedZone){
                    DispatchQueue.main.async {
                        _ = self.dialogOKCancel(messageText: NSLocalizedString("Missing Database", comment:  "zoneNotFound or user deleted"), text: NSLocalizedString("We are sorry, but it seems you do not have a Open Access Helper Database in iCloud. Please add at least one bookmark in OpenAccess Helper for iOS", comment:  ""), cancel: false)
                        
                    }
                }
                else{
                    DispatchQueue.main.async {
                        _ = self.dialogOKCancel(messageText: NSLocalizedString("Connection Error", comment:  "iCloud internet connection"), text: NSLocalizedString("We are sorry, but there was a connection error. Please check your Internet Connection", comment:  ""), cancel: false)
                        
                    }
                }
                print(responseError.localizedDescription as Any)
                
            }
            else {
                if(records?.count == 0){
                    DispatchQueue.main.async {
                        _ = self.dialogOKCancel(messageText: NSLocalizedString("No Bookmarks", comment:  "0 bookmarks retrieved"), text: NSLocalizedString("We were unable to retrieve any bookmarks for you. Are you sure you have bookmarked articles via the Open Access Helper App for iOS?", comment:  ""), cancel: false)
                        
                    }
                }
                records?.forEach({ (record) in
                    
                    guard error == nil else{
                        print(error?.localizedDescription as Any)
                        _ = self.dialogOKCancel(messageText: NSLocalizedString("Record Error", comment:  "iCloud record error"), text: NSLocalizedString("We were unable to retrieve your bookmarks", comment:  ""), cancel: false)
                        return
                    }
                    
                    let bookmark = BookMarkObject()
                    //print(record.value(forKey: "url") ?? "")
                    
                    bookmark.date = record.value(forKey: "date") as! Date
                    bookmark.doi = record.value(forKey: "doi") as! String
                    bookmark.pdf = record.value(forKey: "pdf") as! String
                    bookmark.synced = false
                    bookmark.del = false          //using del rather than deleted, as deleted got me an error
                    bookmark.title = record.value(forKey: "title") as! String
                    bookmark.url = record.value(forKey: "url") as! String
                    bookmark.id = record.value(forKey: "id") as! String
                    
                    bookmarks.append(bookmark)
                })
                completion(bookmarks)
            }
        }
    }
    
    public func deleteBookmark(recordName : String, completion: @escaping (Bool) -> ()){
        //print("recordName: \(recordName)")
        self.privateDatabase.delete(withRecordID: CKRecord.ID(recordName: recordName, zoneID: self.customZone.zoneID)) { (recordId, error) in
            if recordId != nil{
                completion(true)
            }
            if error != nil{
                completion(false)
            }
        }
        
    }
    
    func dialogOKCancel(messageText: String, text: String, cancel: Bool) -> Bool {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("OK", comment:  "OK button in alert"))
        if(cancel){
           alert.addButton(withTitle: NSLocalizedString("Cancel", comment:  "Cancel button in alert"))
        }
        
        return alert.runModal() == .alertFirstButtonReturn
    }
    
}
