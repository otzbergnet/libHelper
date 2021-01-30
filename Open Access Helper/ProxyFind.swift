//
//  ProxyFind.swift
//  Open Access Helper
//
//  Created by Claus Wolf on 12.02.20.
//  Copyright © 2020 Claus Wolf. All rights reserved.
//

import Foundation

class ProxyFind {
    
    func getAPIKeyFromPlist(type: String) -> String{
        //we are going to read the api key for coar.ac.uk from apikey.plist
        //this file isn't the github bundle and as such you'll need to create it yourself, it is a simple Object
        // core : String = API Key from core.ac.uk
        var nsDictionary: NSDictionary?
        if let path = Bundle.main.path(forResource: "apikey", ofType: "plist") {
            nsDictionary = NSDictionary(contentsOfFile: path)
        }
        if let key = nsDictionary?[type]{
            return "\(key)"
        }
        return ""
    }
        
    func askForProxy(domain : String, searchType: String, completion: @escaping (Result<[ProxyInstitute], Error>) -> ()){
        var type = "domain"
        if(searchType == "Name"){
            type = "query"
        }
        
        let apiKey = self.getAPIKeyFromPlist(type: "coreRecommender")
            let apiEndPoint = self.getAPIKeyFromPlist(type: "proxyApi")
            if (apiKey == "") {
                //print("no API Key")
                completion(.failure(NSError(domain: "", code: 441, userInfo: ["description" : "no APIKey Present"])))
                return
            }
            if(apiEndPoint == ""){
                //print("no API EndPoint")
                completion(.failure(NSError(domain: "", code: 442, userInfo: ["description" : "no API End Point Present"])))
                return
            }
            let jsonUrlString = apiEndPoint
            guard let url = URL(string: jsonUrlString) else {
                //print("could not create URL")
                completion(.failure(NSError(domain: "", code: 443, userInfo: ["description" : "could not create URL"])))
                return
            }
            
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

            components.queryItems = [
                URLQueryItem(name: type, value: domain)
            ]

            let query = components.url!.query
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = Data(query!.utf8)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "X-Token")
            
            
            let urlconfig = URLSessionConfiguration.default
            urlconfig.timeoutIntervalForRequest = 10
            urlconfig.timeoutIntervalForResource = 10
            
            let session = URLSession(configuration: urlconfig, delegate: self as? URLSessionDelegate, delegateQueue: nil)
            
            let task = session.dataTask(with: request) {(data, response, error) in
    //            print("The core recommender task took \(timer.stop()) seconds.")
                if let error = error{
                    //we got an error, let's tell the user
                    //print("error")
                    completion(.failure(error))
                    print(error)
                }
                if let data = data {
                    //this worked just fine
                    do {
                        let proxyList = try JSONDecoder().decode(ProxyList.self, from: data)
                        if(proxyList.count == 0){
                            completion(.success(proxyList.data))
                        }
                        else if(proxyList.count > 0){
                            completion(.success(proxyList.data))
                        }
                        else{
                            completion(.failure(NSError(domain: "", code: 440, userInfo: ["description" : "No match found"])))
                        }
                        
                    }
                    catch let jsonError{
                        //print(data)
                        //print("json decode error", jsonError)
                        print("JSON String: \(String(data: data, encoding: .utf8) ?? "JSON ERROR COULD NOT PRINT")")
                        completion(.failure(jsonError))
                    }
                }
                else{
                    //another error
                    //print("failed to get data")
                    completion(.failure(NSError(domain: "", code: 440, userInfo: ["description" : "failed to get data"])))
                    return
                }
                
            }
            task.resume()
            
        }
    
}

struct ProxyList : Decodable{
    var data : [ProxyInstitute] = []
    var code : Int = 0
    var count : Int = 0
}

struct ProxyInstitute : Decodable{
    var id = ""
    var institution = ""
    var proxyUrl = ""
    var ill = ""
    var country = ""
}
