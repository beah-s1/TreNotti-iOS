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
import KeychainAccess
import SwiftUI

//MARK: Main Controller
class TNController: NSObject, ObservableObject, CLLocationManagerDelegate{
    private let env = Env()
    private var railwayList = [OdptRailway]()
    private var nearStationList = [OdptStation]()
    
    private var locationManager = CLLocationManager()
    private var keyStore = Keychain(service: Bundle.main.bundleIdentifier!)
    
    // 運行情報
    @Published var registeredRailwayTrainInformation = [OdptTrainInformation]()
    @Published var otherRailwayTrainInformation = [OdptTrainInformation]()
    
    // 通信などでエラーが発生した場合に、エラーメッセージを格納する→Alertを表示する
    @Published var isAlert = false
    @Published var alertTitle = ""
    @Published var alertDescription = ""
    
    // APIに登録された路線のリスト（String）
    var registeredRailwayList = [String]()
    
    // データベース
    let db = try! Realm()
    
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
        
        // 運行情報が利用可能な事業者の取得
        guard let trainInformationAvailabilityFileUrl = Bundle.main.path(forResource: "train_information_availability", ofType: "json") else{
            assert(false, "FAILED TO GET TRAIN INFORMATION AVAILABILITY JSON FILE")
        }
        
        do{
            let trainInformationAvailabilityJsonFileString = try String(contentsOfFile: trainInformationAvailabilityFileUrl)
            let trainInformationAvailability = try JSONDecoder().decode([String].self, from: trainInformationAvailabilityJsonFileString.data(using: .utf8)!)
            
            // 運行情報が利用可能な路線のみ表示するようフィルタする
            self.railwayList = self.railwayList.filter({ trainInformationAvailability.contains($0.odptOperator) })
        }catch{
            assert(false, "FAILED TO PARSE TRAIN INFORMATION AVAILABILITY JSON FILE")
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
        
        self.updateTrainStatus()
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
        
        updateRegisteredRailwayList()
    }
    
    func updateRegisteredRailwayList(){
        var nearRailwayList = self.nearStationList.map{ $0.railway }
        
        // 手動で選択された路線を追加する
        let manualRegisteredRailwayList = db.objects(ManualRegisteredRailway.self).map{ $0.railway }
        nearRailwayList += manualRegisteredRailwayList
        
        guard let apiKey = self.keyStore["trenotti_api_key"] else{
            assert(false, "API KEY IS INVALID")
        }
        
        var headers = HTTPHeaders()
        headers["Authorization"] = apiKey
        var parameters = Parameters()
        parameters["odpt:railway"] = nearRailwayList.joined(separator: ",")
        
        AF.request(URL(string: "\(env.apiUrl)/api/railway")!, method: .post, parameters: parameters, headers: headers).responseData { (response) in
            if response.response?.statusCode != 200{
                self.alertTitle = "エラー"
                self.alertDescription = "路線情報の登録に失敗しました"
                self.isAlert = true
                
                return
            }
            
            guard let responseData = response.data else{
                assert(false, "INTERNAL SERVER ERROR")
            }
            
            self.registeredRailwayList = try! JSONDecoder().decode([String].self, from: responseData)
            print(self.registeredRailwayList)
            
            self.updateTrainStatus()
        }
    }
    
    func updateTrainStatus(){
        self.registeredRailwayTrainInformation.removeAll()
        self.otherRailwayTrainInformation.removeAll()
        
        guard let apiKey = self.keyStore["trenotti_api_key"] else{
            assert(false, "API KEY IS INVALID")
        }
        
        var headers = HTTPHeaders()
        headers["Authorization"] = apiKey
        AF.request(URL(string: "\(env.apiUrl)/api/train-status")!, method: .get, headers: headers).responseData { (response) in
            if response.response?.statusCode != 200{
                self.alertTitle = "エラー"
                self.alertDescription = "運行情報の取得に失敗しました"
                self.isAlert = true
                return
            }
            
            guard let responseData = response.data else{
                assert(false, "INTERNAL SERVER ERROR")
            }
            
            do{
                let trainStatus = try JSONDecoder().decode([OdptTrainInformation].self, from: responseData)
                
                for s in trainStatus{
                    if self.registeredRailwayList.contains(s.odptRailway){
                        self.registeredRailwayTrainInformation.append(s)
                    }else{
                        self.otherRailwayTrainInformation.append(s)
                    }
                }
                
                self.registeredRailwayTrainInformation.sort(by: { $0.sameAs < $1.sameAs })
                self.otherRailwayTrainInformation.sort(by: { $0.sameAs < $1.sameAs })
            }catch{
                assert(false, "FAILED TO PARSE TRAIN STATUS DATA")
            }
            
            print(self.registeredRailwayTrainInformation)
        }
    }
    
    func getRailway(key: String) -> OdptRailway{
        let filteredRailwayList = self.railwayList.filter({ $0.sameAs == key })
        
        print(key)
        
        if filteredRailwayList.count != 0{
            return filteredRailwayList[0]
        }
        
        // 存在しない場合でも、未定義を指すデータを返す
        let data = OdptRailway(type: "odpt:railway",
                               sameAs: "odpt.Railway:Undefined.Undefined.Undefined",
                               dcTitle: "未定義",
                               railwayTitle: OdptTitle(ja: "未定義", en: "undefined"),
                               odptOperator: "odpt.Operator:Undefined",
                               lineCode: nil,
                               odptColor: nil,
                               ascendingRailDirection: nil,
                               descendingRailDirection: nil,
                               stationOrder: [])
        return data
    }
}

//MARK: 路線運行情報の詳細表示のController
class TNTrainInformationController: NSObject, ObservableObject{
    @Published var status: OdptTrainInformation!
    
    var isRegistered: Bool{
        return self.db.objects(ManualRegisteredRailway.self).filter{ $0.railway == self.status.odptRailway }.count == 0 ? false : true
    }
    
    let db = try! Realm()
    
    init(_ trainStatus: OdptTrainInformation){
        self.status = trainStatus
    }
    
    override init(){
        
    }
    
    func register(){
        // 路線を常に通知させるように登録する
        let data = ManualRegisteredRailway()
        data.railway = self.status.odptRailway
        
        try! db.write{
            db.add(data)
        }
    }
    
    func unregister(){
        // 登録路線から削除
        let data = db.objects(ManualRegisteredRailway.self).filter{ $0.railway == self.status.odptRailway }
        
        try! db.write{
            db.delete(data)
        }
    }
}

//MARK: API Responseの定義
struct ApiResponse: Codable{
    var status: String
    var description: String?
    var token: String?
}

struct OdptRailway: Codable{
    var type: String
    var sameAs: String
    var dcTitle: String
    var railwayTitle: OdptTitle
    var odptOperator: String
    var lineCode: String?
    var odptColor: String?
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
        case odptColor = "odpt:color"
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
    
    var color: Color{
        guard let c = self.odptColor else{
            return Color.gray
        }
        
        let v = Int("000000" + c, radix: 16) ?? 0
        return Color(hex: v)
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

struct OdptTrainInformation: Codable, Identifiable{
    var id: String
    var sameAs: String
    var odptOperator: String
    var odptRailway: String
    var odptTrainInformationStatus: OdptTitle?
    var odptTrainInformationText: OdptTitle?
    var railDirection: String?
    var odptTrainInformationCause: OdptTitle?
    
    enum CodingKeys: String, CodingKey{
        case id = "@id"
        case sameAs = "owl:sameAs"
        case odptOperator = "odpt:operator"
        case odptRailway = "odpt:railway"
        case odptTrainInformationStatus = "odpt:trainInformationStatus"
        case odptTrainInformationText = "odpt:trainInformationText"
        case railDirection = "odpt:railDirection"
        case odptTrainInformationCause = "odpt:trainInformationCause"
    }
    
    var trainInformationStatus: OdptTitle{
        guard let status = self.odptTrainInformationStatus else{
            return OdptTitle(ja: "平常運転", en: "Service on schedule")
        }
        
        return status
    }
    
    var trainInformationText: OdptTitle{
        guard let status = self.odptTrainInformationText else{
            return OdptTitle(ja: "現在平常通り運行しています。", en: nil)
        }
        
        return status
    }
}


struct OdptTitle: Codable{
    var ja: String
    var en: String?
}

//MARK: データベースに保存するデータの定義
class ManualRegisteredRailway: Object{
    @objc dynamic var railway: String = ""
}
