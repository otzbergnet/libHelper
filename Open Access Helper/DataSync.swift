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
                print(responseError.localizedDescription as Any)
            }
            else {
                records?.forEach({ (record) in
                    
                    guard error == nil else{
                        print(error?.localizedDescription as Any)
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
    
}


/*
 //
 //  DataSync.swift
 //  oaHelperiOS
 //
 //  Created by Claus Wolf on 01.03.19.
 //  Copyright © 2019 Claus Wolf. All rights reserved.
 //
 
 import UIKit
 import CloudKit
 import CommonCrypto
 
 class DataSync: UIViewController {
 
 //var bookMark: CKRecord?
 var newBookMark: Bool = true
 var bookMarkData = BookMarkData()
 var bookMarkList : [BookMark] = []
 
 //CloudKit DB & ZONE
 let defaultContainer = CKContainer(identifier: "iCloud.net.otzberg.oaHelper")
 let privateDatabase = CKContainer(identifier: "iCloud.net.otzberg.oaHelper").privateCloudDatabase
 let customZone = CKRecordZone(zoneName: "bookMarkZone")
 
 public func fetchUserRecordID() {
 
 // Fetch User Record
 self.defaultContainer.fetchUserRecordID { (recordID, error) -> Void in
 if let responseError = error {
 print(responseError)
 
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
 
 } else if record != nil {
 self.fetchBookMarks()
 }
 }
 }
 
 private func fetchBookMarks() {
 
 // Initialize Query
 let query = CKQuery(recordType: "Bookmarks", predicate: NSPredicate(value: true))
 
 // Configure Query
 //query.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
 
 // Perform Query
 self.privateDatabase.perform(query, inZoneWith: self.customZone.zoneID) { (records, error) in
 if let responseError = error{
 print(responseError.localizedDescription as Any)
 }
 else {
 records?.forEach({ (record) in
 
 guard error == nil else{
 print(error?.localizedDescription as Any)
 return
 }
 
 print(record.value(forKey: "url") ?? "")
 })
 }
 
 
 }
 }
 
 public func saveBookmark(url: NSString, title: NSString, recordName: String){
 
 
 
 let bookMark = CKRecord(recordType: "Bookmarks", recordID: CKRecord.ID(recordName: recordName, zoneID: self.customZone.zoneID))
 
 // Configure Record
 bookMark.setObject(url, forKey: "url")
 bookMark.setObject(title, forKey: "title")
 
 // Save Record
 self.privateDatabase.save(bookMark) { (record, error) -> Void in
 DispatchQueue.main.sync {
 // Process Response
 self.processResponse(record: record, error: error as? CKError)
 }
 
 }
 }
 
 // MARK: Helper Methods
 private func processResponse(record: CKRecord?, error: CKError?) {
 var message = ""
 
 if let error = error {
 message = "We were not able to save your bookmark - error: \(error.errorCode)."
 
 }
 else if record == nil {
 message = "We were not able to save your bookmark."
 }
 
 if !message.isEmpty {
 
 print(message)
 /*
 // Initialize Alert Controller
 let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
 
 // Present Alert Controller
 present(alertController, animated: true, completion: nil)*/
 
 } else {
 // Notify Delegate
 if newBookMark {
 //delegate?.controller(controller: self, didAddList: list!)
 print("didAddList")
 } else {
 //delegate?.controller(controller: self, didUpdateList: list!)
 print("didUpdateList")
 }
 }
 }
 
 public func syncAllBookmarks(){
 let coreBookmarks = self.bookMarkData.getAllBookMarks()
 for cBookmark in coreBookmarks{
 if let url = cBookmark.url {
 if let hash = md5(url) {
 let recordName = "url_\(hash)"
 saveBookmark(url: url as NSString, title: "\(String(describing: cBookmark.title!))" as NSString, recordName: recordName)
 }
 else{
 print("unable to hash URL")
 }
 }
 else{
 print("no url present")
 }
 
 }
 }
 
 func md5(_ string: String) -> String? {
 let length = Int(CC_MD5_DIGEST_LENGTH)
 var digest = [UInt8](repeating: 0, count: length)
 
 if let d = string.data(using: String.Encoding.utf8) {
 _ = d.withUnsafeBytes { (body: UnsafePointer<UInt8>) in
 CC_MD5(body, CC_LONG(d.count), &digest)
 }
 }
 
 return (0..<length).reduce("") {
 $0 + String(format: "%02x", digest[$1])
 }
 }
 
 }

 
 */
