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
    
    var body: some View {
        NavigationView{
            Form{
                Section(header: Text("登録済みの路線")){
                    List{
                        ForEach(controller.registeredRailwayTrainInformation){ information in
                            StatusCell(railwayTitle: "\(controller.getRailway(key: information.odptRailway).railwayTitle.ja)",
                                       railwayStatus: "\(information.trainInformationStatus.ja)")
                        }
                    }
                }
                
                Section(header: Text("その他の路線")) {
                    List{
                        ForEach(controller.otherRailwayTrainInformation){ information in
                            StatusCell(railwayTitle: "\(controller.getRailway(key: information.odptRailway).railwayTitle.ja)",
                                       railwayStatus: "\(information.trainInformationStatus.ja)")
                        }
                    }
                }
            }
            .alert(isPresented: $controller.isAlert, content: {
                Alert(title: Text(controller.alertTitle),
                      message: Text(controller.alertDescription),
                      dismissButton: .default(Text("OK")))
            })
            .navigationBarTitle(.init("運行情報一覧"))
            
        }
    }
}

struct StatusCell: View {
    var railwayTitle: String
    var railwayStatus: String
    
    var body: some View{
        HStack{
            Rectangle()
                .fill(Color.gray)
                .frame(width: 30)
                .padding([.top, .bottom], -10)
                .padding(.leading, -16)
            
            VStack(alignment: .leading){
                Text(railwayTitle)
                    .font(.title2)
                    .padding(.top, 3.0)
                Text(railwayStatus)
                    .font(.body)
                    .padding(3)
            }
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
