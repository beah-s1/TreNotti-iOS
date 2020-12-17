//
//  TrainStatusCell.swift
//  TreNotti
//
//  Created by Kentaro Abe on 2020/12/08.
//

import SwiftUI

struct TrainStatusCell: View {
    var railwayTitle: String
    var railwayStatus: String
    
    var body: some View{
        HStack{
            Rectangle()
                .fill(Color.black)
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

struct TrainStatusCell_Previews: PreviewProvider {
    static var previews: some View {
        TrainStatusCell(railwayTitle: "AA鉄道 AA線", railwayStatus: "平常運行")
            .previewDisplayName("a")
    }
}
