//
//  TrainStatusView.swift
//  TreNotti
//
//  Created by Kentaro Abe on 2020/12/08.
//
//  運行情報一覧画面

import SwiftUI

struct TrainStatusView: View {
    var body: some View {
        NavigationView{
            Form{
                Section(header: Text("現在地付近の路線")){
                    List{
                        StatusCell(railwayTitle: "AA鉄道 BB線", railwayStatus: "平常運行")
                    }
                }
                
                Section(header: Text("手動で登録済みの路線")) {
                    List{
                        StatusCell(railwayTitle: "AA鉄道 BB線", railwayStatus: "遅延")
                        StatusCell(railwayTitle: "AA鉄道 CC線", railwayStatus: "運転再開見込")
                    }
                }
            }
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
                .padding(.leading, -20)
            
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
            TrainStatusView()
                .previewDevice("iPhone 11")
        }
    }
}
