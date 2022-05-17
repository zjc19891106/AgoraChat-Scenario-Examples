//
//  AppDelegate.swift
//  AgoraChatEThreeExample
//
//  Created by 朱继超 on 2022/4/20.
//

import UIKit
@_exported import AgoraChat
@_exported import ProgressHUD
import ZSwiftBaseLib

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private let appKey = "41117440#383391"
    
    @UserDefault("AgoraChatUserName", defaultValue: "") var userName
    
    @UserDefault("AgoraChatPassword", defaultValue: "") var passWord

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = .white
        let VC = ViewController.init();
        VC.title = "AgoraChat E3 Example"
        let nav = UINavigationController(rootViewController: VC)
        self.window?.rootViewController = nav
        self.window?.becomeFirstResponder()
        self.window?.makeKeyAndVisible()
        self.agoraChatInitlize()
        if !(AgoraChatClient.shared().currentUsername ?? "").isEmpty {
            ProgressHUD.show("Relogining...", interaction: false)
            AgoraChatRequest.shared.loginToAppSever(userName: self.userName, passWord: self.passWord) { dic, code in
                ProgressHUD.dismiss()
                if code == 200 {
                    if let token = dic["accessToken"] as? String,let loginName = dic["chatUserName"] as? String,token.count > 0 {
                        ProgressHUD.show("Generate token...", interaction: false)
                        self.agoraChatLogin(loginName: loginName, token: token)
                    }
                } else {
                    let errorInfo = dic["errorInfo"] ?? ""
                    ProgressHUD.showError(errorInfo as? String)
                }
            }
        }
        return true
    }
    
    /// register agoraChatSDK
    private func agoraChatInitlize() {
        let options = AgoraChatOptions(appkey: self.appKey)
        options?.enableConsoleLog = true
        options?.isAutoLogin = true
        AgoraChatClient.shared().initializeSDK(with: options)
    }
    
    private func agoraChatLogin(loginName: String,token:String) {
        AgoraChatClient.shared().login(withUsername: loginName, agoraToken: token) { reponse, error in
            ProgressHUD.dismiss()
            if error?.code.rawValue == 200 {
                self.userName = loginName
                self.authE3(userName: loginName)
            } else {
                ProgressHUD.showError(error?.errorDescription)
            }
        }
    }
    
    private func authE3(userName: String) {
        ProgressHUD.show("E3Authenticate...", interaction: false)
        AgoraChatRequest.shared.e3Authenticate(userName: userName) { token, error in
            ProgressHUD.dismiss()
            if token != nil {
                ProgressHUD.show("createEThree...", interaction: false)
                E3EncryptoManager.shared.createEThree(token,userName)
                let e = E3EncryptoManager.shared.e3
                //MARK: - cleanup userinfo include group cache
//                if (try? e?.hasLocalPrivateKey()) == true {
//                    try? e?.cleanUp()
//                }
                e?.register(completion: { error in
                    ProgressHUD.dismiss()
                    do {
                        try E3EncryptoManager.shared.card = e?.findUser(with: userName).startSync(timeout: 3).get()
                        E3EncryptoManager.shared.cards![E3EncryptoManager.shared.card!.identity] = E3EncryptoManager.shared.card
                    } catch {
                        ProgressHUD.showError(error.localizedDescription)
                    }
                    //MARK: - rotatePrivateKey
//                    if error as? EThreeError == .userIsAlreadyRegistered {
//                        e?.rotatePrivateKey { error in
//                            ProgressHUD.dismiss()
//                            if error == nil {
//                                ProgressHUD.showSuccess("Rotated private key instead")
//                            } else {
//                                ProgressHUD.showError(error?.localizedDescription)
//                            }
//                        }
//                        return
//                    }
                    ProgressHUD.showError(error?.localizedDescription)
                })
            }
        }
    }
    
}
