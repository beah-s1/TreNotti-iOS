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

class TNController: NSObject, ObservableObject, CLLocationManagerDelegate{
    private let env = Env()
    private var railwayList = [OdptRailway]()
    private var nearStationList = [OdptStation]()
    
    private var locationManager = CLLocationManager()
    
    override init(){
        super.init()
        
        // ベースとなる路線情報の取得（ローカルファイルから全件）
        guard let railwayJsonFileUrl = Bundle.main.path(forResource: "railway", ofType: "json") else{
            assert(false, "FAILED TO GET RAILWAY JSON FILE")
        }
        
        do{
            let railwayJsonFileString = try String(contentsOfFile: railwayJsonFileUrl)
            self.railwayList = try JSONDecoder().decode([OdptRailway].self, from: railwayJsonFileString.data(using: .utf8)!)
        }catch{
            assert(false, "FAILED TO PARSE RAILWAY JSON FILE")
        }
        
        // 位置情報関係
        locationManager.delegate = self
        
        if locationManager.authorizationStatus == .restricted || locationManager.authorizationStatus == .denied{
            return
        }else if locationManager.authorizationStatus == .notDetermined{
            locationManager.requestAlwaysAuthorization()
        }
        
        // 大幅位置情報変更サービスの利用
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 位置情報が変更されたとき
        self.nearStationList.removeAll()
        
        for location in locations{
            let queue = DispatchQueue.global()
            let semaphore = DispatchSemaphore(value: 0)
            
            let url = URL(string: "\(env.odptApiBaseUrl)/api/v4/places/odpt:Station?lon=\(location.coordinate.longitude)&lat=\(location.coordinate.latitude)&radius=1000&acl:consumerKey=\(env.odptApiKey)")!
            AF.request(url).responseData(queue: queue) { (response) in
                switch response.result{
                case .success(let result):
                    do{
                        self.nearStationList += (try JSONDecoder().decode([OdptStation].self, from: result))
                    }catch{
                        assert(false, "COULD NOT PARSE ODPT API")
                    }
                case .failure(let error):
                    assert(false, error.localizedDescription)
                }
                
                semaphore.signal()
            }
            semaphore.wait()
        }
        
        // とれノッチAPIへの登録処理
        let nearRailwayList = self.nearStationList.map{ $0.railway }
        
    }
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
    var stationOrder: [StationOrder]
    
    enum CodingKeys: String, CodingKey{
        case type = "@type"
        case sameAs = "owl:sameAs"
        case dcTitle = "dc:title"
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

struct OdptStation: Codable{
    var type: String
    var sameAs: String
    var dcTitle: String
    var stationTitle: OdptTitle
    var odptOperator: String
    var railway: String
    var stationCode: String?
    var connectingRailway: [String]?
    var stationTimetable: [String]?
    
    enum CodingKeys: String, CodingKey{
        case type = "@type"
        case sameAs = "owl:sameAs"
        case dcTitle = "dc:title"
        case stationTitle = "odpt:stationTitle"
        case odptOperator = "odpt:operator"
        case railway = "odpt:railway"
        case stationCode = "odpt:stationCode"
        case connectingRailway = "odpt:connectingRailway"
        case stationTimetable = "odpt:stationTimetable"
    }
}


struct OdptTitle: Codable{
    var ja: String
    var en: String?
}
