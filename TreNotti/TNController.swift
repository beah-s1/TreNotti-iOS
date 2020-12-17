//
//  TNController.swift
//  TreNotti
//
//  Created by Kentaro Abe on 2020/12/18.
//

import Foundation
import Alamofire
import RealmSwift
import CoreLocation

class TNController{
    private let env = Env()
    
}

struct OdptRailway: Codable{
    var type: String
    var sameAs: String
    var dcTitle: String
    var railwayTitle: OdptTitle
    var odptOperator: String
    var lineCode: String?
    var color: String?
    var ascendingRailDirection: String?
    var descendingRailDirection: String?
    var stationOrder: StationOrder
    
    enum CodingKeys: String, CodingKey{
        case type = "@type"
        case sameAs = "owl:sameAs"
        case dcTitle = "dc:Title"
        case railwayTitle = "odpt:railwayTitle"
        case odptOperator = "odpt:operator"
        case lineCode = "odpt:lineCode"
        case color = "odpt:color"
        case ascendingRailDirection = "odpt:ascendingRailDirection"
        case descendingRailDirection = "odpt:descendingRailDirection"
        case stationOrder = "odpt:stationOrder"
    }
    
    struct StationOrder: Codable{
        var index: Int
        var station: String
        
        enum CodingKeys: String, CodingKey{
            case index = "odpt:index"
            case station = "odpt:station"
        }
    }
}


struct OdptTitle: Codable{
    var ja: String
    var en: String?
}
