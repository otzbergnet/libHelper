//
//  StatisticSubmit.swift
//  Open Access Helper
//
//  Created by Claus Wolf on 19.02.20.
//  Copyright © 2020 Claus Wolf. All rights reserved.
//

import Foundation

class StatisticSubmit {
    
    var uid : String
    let settings = Preferences()
    
    init(){
        let uuid = self.settings.getStringValue(key: "uuid")
        if(uuid == ""){
            let myuuid =  UUID().uuidString
            self.settings.setStringValue(key: "uuid", value: myuuid)
        }
        uid = uuid
    }
    
    func submitStats(force : Bool = false){
        
        let submit = self.settings.getValue(key: "shareStats")
        let stringDate = self.getDate()
        let lastDate = self.settings.getShareDate()
        
        if(!submit && !force){
//            print("statistics submit is false")
            return
        }
        
        if(!force && recentUpdate(lastDate: lastDate)){
//            print("recently updatd statistics")
            return
        }
        
        let oa_found = replaceZeroWithUndersore(value: self.settings.getIntVal(key: "oaFoundCount"))
        let oa_search = replaceZeroWithUndersore(value: self.settings.getIntVal(key: "oaSearchCount"))
        let proxy_count = replaceZeroWithUndersore(value: self.settings.getIntVal(key: "ezProxyCount"))
        let core_pdf = 0
        let bookmark_count = 0
        let recom_count = 0
        let recom_view = 0
        
        
        if(oa_found == "_" && oa_search == "_" && proxy_count == "_"){
//            print("nothing to share")
            return
        }
        
        
        let urlString = "https://www.oahelper.org/stat.php?oa_search=\(oa_search)&oa_found=\(oa_found)&core_pdf=\(core_pdf)&bookmark_count=\(bookmark_count)&recom_count=\(recom_count)&recom_view=\(recom_view)&proxy_count=\(proxy_count)&uid=\(self.uid)&os=macos"
        guard let url = URL(string: urlString) else {
            return
        }
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                    print(error)
            }
            if let data = data {
                    do{
                        let myData = try JSONDecoder().decode(Status.self, from: data)
                        if myData.status == 200 {
//                            print("success")
                            self.settings.setDate(date : stringDate)
                        }
                        else{
                            print("another code received \(myData.status)")
                        }
                    }
                    catch let jsonError{
                        print("\(jsonError)")
                    }
            }
            else{
                print("data error")
                return
            }
        }
        task.resume()
    }
    
    func getDate() -> String{
        
        let currentDate = Date();
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let newDate = formatter.string(from: currentDate)
        
        return newDate

    }
    
    func replaceZeroWithUndersore(value : Int) -> String {
        var returnValue = ""
        if(value == 0){
            returnValue = "_"
        }
        else{
            returnValue = "\(value)"
        }
        return returnValue
    }
    
    func recentUpdate(lastDate: String) -> Bool{
        if(lastDate == "0"){
            return false
        }
        var returnValue = false
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let oldDate = dateFormatter.date(from: lastDate) {
            let newDate = Date()
            if let diffInDays = Calendar.current.dateComponents([.day], from: oldDate, to: newDate).day {
                if(diffInDays < 31){
                    returnValue = true
                }
            }
        }
        return returnValue
    }
}

struct Status : Decodable {
    let status : Int
}
