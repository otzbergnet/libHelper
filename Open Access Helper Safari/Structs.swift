//
//  Structs.swift
//  Open Access Helper Safari
//
//  Created by Claus Wolf on 05.01.20.
//  Copyright © 2020 Claus Wolf. All rights reserved.
//

import Foundation

// MARK:  Unpaywall Related Structs

struct OaDOI : Decodable {
    let url : String
    //let final : String
    let status : String
}

struct Unpaywall : Decodable{
    let best_oa_location : OpenAccessLocation?
    let data_standard : Int
    let doi : String
    let doi_url : String
    let genre : String
    let is_oa : Bool
    let journal_is_in_doaj: Bool
    let journal_is_oa : Bool
    let journal_issns : String?
    let journal_name : String?
    let oa_locations : [OpenAccessLocation]
    let published_date : String?
    let publisher : String?
    let title : String?
    let updated : String?
    let year : Int?
    let z_authors : [OAAuthors]?
}

struct OpenAccessLocation : Decodable {
    let evidence : String
    let host_type : String
    let is_best : Bool
    let license : String?
    let pmh_id : String?
    let updated : String?
    let url : String
    let url_for_landing_page : String?
    let url_for_pdf : String?
    let version : String?
}

struct OAAuthors : Decodable{
    
    let orcid : String?
    let authenticated_orcid : Bool?
    let family : String?
    let given : String?
    let sequence : String?
    
    enum CodingKeys: String, CodingKey {
        case authenticated_orcid = "authenticated-orcid"
        case orcid = "ORCID"
        case family = "family"
        case given = "given"
        case sequence = "sequence"
    }
}

// MARK:  CORE DISCOVERY Related Structs

struct Coredata : Decodable{
    let fullTextLink : String?
    let source : String?
}

// MARK:  Open Access Button Related Structs

struct OaButton : Decodable{
    let data : OAData
}

struct OAData : Decodable{
    let availability : [OAAvailability?]?
    let requests : [OARequests?]?
}

struct OAAvailability : Decodable{
    let type : String?
    let url : String?
}

struct OARequests : Decodable {
    let type : String?
    let id : String?
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case id = "_id"
    }
}

struct OARequestData : Decodable{
    let data : OARequestObject
}

struct OARequestObject : Decodable{
    let status : String?
    let received : OAReceivedObject?
}

struct OAReceivedObject : Decodable{
    let url : String?
}

// MARK:  CORE Recommender Related Structs

struct CoreRecommender : Decodable{
    var msg : String
    var code : Int
    var data : [CoreRecommendations]
}

struct CoreRecommendations : Codable{
    var title : String
    var year : String
    var author : String
    var link : String
}

class CoreRequestObject{
    var doi = ""
    var title = ""
    var aabstract = ""
    var author = ""
    var referer = ""
    var fulltextUrl = ""
}

