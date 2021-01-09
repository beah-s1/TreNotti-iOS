//
//  TreNottiApp.swift
//  TreNotti
//
//  Created by Kentaro Abe on 2020/12/08.
//

import SwiftUI
import Alamofire
import KeychainAccess

@main
struct TreNottiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            TrainStatusView()
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate{
    let env = Env()
    let keyStore = Keychain(service: Bundle.main.bundleIdentifier!)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // APIキー取得済みか確認→なければ取得
        if !(keyStore["trenotti_api_key"] != nil){
            var parameters = Parameters()
            parameters["device_type"] = "ios"
            
            let queue = DispatchQueue.global(qos: .utility)
            let semaphore = DispatchSemaphore(value: 0)
            
            AF.request(URL(string: "\(env.apiUrl)/api/auth/issue-key")!, method: .post, parameters: parameters).responseData(queue: queue) { (response) in
                switch response.result{
                case .success(let result):
                    do{
                        let data = try JSONDecoder().decode(ApiResponse.self, from: result)
                        guard let key = data.token else{
                            assert(false, "FAILED TO GET API TOKEN")
                        }
                        
                        self.keyStore["trenotti_api_key"] = key
                    }catch{
                        assert(false, "FAILED TO GET API TOKEN")
                    }
                    break
                case .failure(let error):
                    print(error.errorDescription != nil ? error.errorDescription! : "Unknown Error")
                }
                
                semaphore.signal()
            }
            
            semaphore.wait()
        }
        
        // プッシュ通知関係
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if error != nil{
                print(error.debugDescription)
                return
            }
            
            if granted{
                // デバイストークンの要求
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard let apiKey = keyStore["trenotti_api_key"] else{
            return
        }
        
        var headers = HTTPHeaders()
        headers["Authorization"] = apiKey
        var parameters = Parameters()
        parameters["token"] = deviceToken.map{ String(format: "%02hhx", $0) }.joined()
        
        AF.request(URL(string: "\(env.apiUrl)/api/device")!, method: .post, parameters: parameters, headers: headers).responseData { (response) in
            switch response.result{
            case .success(let result):
                guard let response = try? JSONDecoder().decode(ApiResponse.self, from: result) else{
                    assert(false, "FAILED TO PARSE API RESPONSE")
                }
                
                if let responseMessage = response.description{
                    print(responseMessage)
                }
                
                break
            default: return
            }
            
        }
    }
}
