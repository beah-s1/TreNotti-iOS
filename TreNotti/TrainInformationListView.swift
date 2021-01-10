//
//  TrainInformationListView.swift
//  TreNotti
//
//  Created by Kentaro Abe on 2020/12/08.
//
//  運行情報一覧画面

import SwiftUI

struct TrainInformationListView: View {
    @ObservedObject var controller = TNController()
    @State var isPresentInformationDescription = false
    @State var isPresentFirstLaunchAlert = false
    @ObservedObject var informationViewController = TNTrainInformationController()
    
    var body: some View {
        NavigationView{
            Form{
                Section(header: Text("登録済みの路線")){
                    List{
                        ForEach(controller.registeredRailwayTrainInformation){ information in
                            let r = controller.getRailway(key: information.odptRailway)
                            StatusCell(railwayTitle: "\(r.railwayTitle.ja)",
                                       railwayStatus: "\(information.trainInformationStatus.ja)",
                                       isPresentDescription: isPresentInformationDescription,
                                       railwayColor: r.color)
                                .onTapGesture {
                                    self.informationViewController.railway = r
                                    self.informationViewController.status = information
                                    self.isPresentInformationDescription.toggle()
                                }
                        }
                    }
                }
                
                Section(header: Text("その他の路線")) {
                    List{
                        ForEach(controller.otherRailwayTrainInformation){ information in
                            let r = controller.getRailway(key: information.odptRailway)
                            StatusCell(railwayTitle: "\(r.railwayTitle.ja)",
                                       railwayStatus: "\(information.trainInformationStatus.ja)",
                                       isPresentDescription: isPresentInformationDescription,
                                       railwayColor: r.color)
                                .onTapGesture {
                                    self.informationViewController.railway = r
                                    self.informationViewController.status = information
                                    self.isPresentInformationDescription.toggle()
                                }
                        }
                    }
                }
            }
            .alert(isPresented: $controller.isAlert, content: {
                Alert(title: Text(controller.alertTitle),
                      message: Text(controller.alertDescription),
                      dismissButton: .default(Text("OK")))
            })
            .alert(isPresented: $isPresentFirstLaunchAlert) {
                Alert(title: Text("インストールありがとうございます！"),
                      message: Text("バックグラウンドでも、現在地に基づいた運行情報を取得するため、設定アプリから位置情報の利用許可を「常に許可」に変更してください。"),
                      dismissButton: .default(Text("設定を開く"),
                                              action: {
                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                                              })
                      )
            }
            .sheet(isPresented: $isPresentInformationDescription, onDismiss: {
                try! self.controller.updateRegisteredRailwayList()
            }){
                TrainInformationView(controller: informationViewController,
                                     isPresent: $isPresentInformationDescription)
            }
            .onAppear(){
                let s = UserDefaults.standard
                if s.object(forKey: "trenotti.isFirstLaunch") != nil{
                    return
                }else{
                    s.setValue(false, forKey: "trenotti.isFirstLaunch")
                    self.isPresentFirstLaunchAlert = true
                }
            }
            .navigationBarTitle(.init("運行情報一覧"))
            
        }
    }
}

struct StatusCell: View {
    var railwayTitle: String
    var railwayStatus: String
    @State var isPresentDescription: Bool
    var railwayColor: Color
    
    var body: some View{
        HStack(alignment: .center){
            Rectangle()
                .fill(railwayColor)
                .frame(width: 30)
                .padding([.top, .bottom], -6)
                .padding(.leading, -16)
            
            VStack(alignment: .leading){
                Text(railwayTitle)
                    .font(.title2)
                    .padding(.top, 3.0)
                Text(railwayStatus)
                    .font(.body)
                    .padding(3)
            }
            
            Spacer()
            
            Button(action: {
                self.isPresentDescription.toggle()
            }, label: {
                Image(systemName: "info.circle")
            })
        }
    }
}

struct TrainStatusView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TrainInformationListView()
                .previewDevice("iPhone 11")
        }
    }
}

extension Color {
    init(hex: Int, alpha: Double = 1) {
        let components = (
            R: Double((hex >> 16) & 0xff) / 255,
            G: Double((hex >> 08) & 0xff) / 255,
            B: Double((hex >> 00) & 0xff) / 255
        )
        self.init(
            .sRGB,
            red: components.R,
            green: components.G,
            blue: components.B,
            opacity: alpha
        )
    }
}
