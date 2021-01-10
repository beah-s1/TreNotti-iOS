//
//  SettingsView.swift
//  TreNotti
//
//  Created by Kentaro Abe on 2021/01/10.
//

import SwiftUI

struct SettingsView: View {
    let env = Env()
    var body: some View {
        NavigationView{
            Form{
                Section(header: Text("App情報")){
                    List{
                        HStack{
                            Text("Version")
                            Spacer()
                            Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)
                        }
                    }
                }
                
                Section(header: Text("著作権情報")){
                    List{
                        Text("このアプリは、東京公共交通オープンデータチャンレジで提供されるAPIを用いて開発されています。\nデータについては、交通事業者より提供されたデータを使用していますが、データのリアルタイム性・完全性を保証するものではありません。\n本アプリに関して、交通事業者へのお問い合わせはご遠慮ください。")
                    }
                }
                
                Section(header: Text("各種情報")){
                    List{
                        Button("ヘルプ", action: {
                            UIApplication.shared.open(URL(string: env.helpPageUrl)!)
                        })
                        Button("利用規約・プライバシーポリシー", action: {
                            UIApplication.shared.open(URL(string: env.termsAndPrivacyPageUrl)!)
                        })
                        Button("アプリに関してのお問い合わせ", action: {
                            UIApplication.shared.open(URL(string: "mailto:\(env.supportEmail)?subject=\(env.supportEmailTitle)&body=\(String(describing: env.supportEmailBody))")!)
                        })
                    }
                }
            }
            .navigationBarTitle("設定・ヘルプ")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
