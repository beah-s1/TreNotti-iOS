//
//  TrainInformationView.swift
//  TreNotti
//
//  Created by Kentaro Abe on 2021/01/10.
//
//  運行情報詳細画面

import SwiftUI

struct TrainInformationView: View {
    @ObservedObject var controller: TNTrainInformationController
    @State var isRegistered = false
    @Binding var isPresent: Bool
    
    var body: some View {
        NavigationView{
            Form{
                Section(header: Text("運行情報")) {
                    Text(controller.status.trainInformationStatus.ja)
                    Text(controller.status.trainInformationText.ja)
                }
                
                Section(header: Text("設定")) {
                    Toggle(isOn: $isRegistered) {
                        Text("常に通知する")
                    }
                    .onChange(of: isRegistered, perform: { value in
                        switch value{
                        case true:
                            self.controller.register()
                        case false:
                            self.controller.unregister()
                        }
                    })
                }
            }
            .padding()
            .onAppear(){
                self.isRegistered = controller.isRegistered
            }
            
            .navigationBarTitle(self.controller.railway.railwayTitle.ja)
            .navigationBarItems(trailing: Button(action: {
                isPresent.toggle()
            }, label: {
                Text("閉じる")
            }))
        }
    }
}
