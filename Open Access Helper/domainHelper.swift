//
//  domainHelper.swift
//  Open Access Helper
//
//  Created by Claus Wolf on 26.06.21.
//  Copyright © 2021 Claus Wolf. All rights reserved.
//

import Foundation


struct DomainList : Decodable{
    var id : String = ""
    var prefix : String? = ""
    var domains : [String] = []
}

class DomainHelper {
    
    let preferences = Preferences()
    
    func saveDomainList(completion: @escaping (Result<Bool, Error>) -> ()){
        
        let domainUrl = self.preferences.getStringValue(key: "domainUrl")
        if (domainUrl == ""){
            completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : "no valid domainUrl found"])))
            return
        }
        
        let url = URL(string: domainUrl)
        
        let session = URLSession.shared
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request) {(data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : "dataTask failed with error: \(error)"])))
                return
                
            }
            if let data = data {
                // we have data, let's save
                do {
                    let domainList = try JSONDecoder().decode(DomainList.self, from: data)
                    self.preferences.setStringArray(array: domainList.domains, key: "instituteDomains")
                    completion(.success(true))
                }
                catch let jsonError{
                    completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : "jsonDecode Error failed with error: \(jsonError)"])))
                    return
                }
            }
            else{
                completion(.failure(NSError(domain: "", code: 400, userInfo: ["description" : "dataTask failed to get data"])))
                return
            }
            
        }
        
        task.resume()
        
    }
    
    func clearDomainList(completion: @escaping (Result<Bool, Error>) -> ()){
        self.preferences.setStringArray(array: [], key: "instituteDomains")
        completion(.success(true))
    }
    
    
}
