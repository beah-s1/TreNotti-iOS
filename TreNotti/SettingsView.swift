//
//  SettingsView.swift
//  TreNotti
//
//  Created by Kentaro Abe on 2021/01/10.
//

import SwiftUI
import KeychainAccess

struct SettingsView: View {
    @State var isPresentResetAlert = false
    var keyStore = Keychain(service: Bundle.main.bundleIdentifier!)
    
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
                
                Section(header: Text("設定")){
                    List{
                        Button("位置情報・プッシュ通知などの設定", action: {
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        })
                        Button("アプリのリセット", action: {
                            isPresentResetAlert.toggle()
                        })
                    }
                }
                .alert(isPresented: $isPresentResetAlert,
                       content: {
                        Alert(title: Text("リセットしますか？"),
                              message: Text("この操作を行うと、路線の登録など全ての除法が削除されます。\nこの操作は取り消せません。\nよろしいですか？\n\n（リセット後、アプリが自動終了します）"),
                              primaryButton: Alert.Button.cancel(Text("キャンセル")),
                              secondaryButton: Alert.Button.destructive(Text("リセット"),
                                                                        action: {
                                                                            let defaults = UserDefaults.standard
                                                                            defaults.removeObject(forKey: "trenotti.isFirstLaunch")
                                                                            try! keyStore.removeAll()
                                                                            exit(0)
                                                                        }))
                       })
                
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
                
                Section(header: Text("著作権情報")){
                    List{
                        Text("このアプリは、東京公共交通オープンデータチャンレジで提供されるAPIを用いて開発されています。\nデータについては、交通事業者より提供されたデータを使用していますが、データのリアルタイム性・完全性を保証するものではありません。\n本アプリに関して、交通事業者へのお問い合わせはご遠慮ください。")
                        Text("(C)2020 KentaroAbe")
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
