//
//  ContentView.swift
//  TreNotti
//
//  Created by Kentaro Abe on 2020/12/08.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView{
            TrainInformationListView()
                .tabItem {
                    VStack{
                        Image(systemName: "tram")
                        Spacer()
                        Text("運行情報")
                    }
                }
            SettingsView()
                .tabItem {
                    VStack{
                        Image(systemName: "gear")
                        Spacer()
                        Text("設定・ヘルプ")
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
