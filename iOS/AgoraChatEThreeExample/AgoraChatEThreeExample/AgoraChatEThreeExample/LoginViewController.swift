//
//  LoginViewController.swift
//  AgoraChatEThreeExample
//
//  Created by 朱继超 on 2022/4/20.
//

import UIKit


final class LoginViewController: UIViewController,UITextFieldDelegate {
    
    @UserDefault("AgoraChatUserName", defaultValue: "") var userName
    
    @UserDefault("AgoraChatPassword", defaultValue: "") var passWord
    
    private lazy var logo: UIImageView = {
        UIImageView(frame: CGRect(x: ScreenWidth/3.0, y: ZNavgationHeight+20, width: ScreenWidth/3.0, height: ScreenWidth/3.0)).image(UIImage(named: "login_logo")!).contentMode(.scaleAspectFit)
    }()
    
    private lazy var userNameField: UITextField = {
        UITextField(frame: CGRect(x: 20, y: self.logo.frame.maxY+20, width: ScreenWidth - 40, height: 40)).cornerRadius(5).placeholder("UserName").delegate(self).tag(111).layerProperties(UIColor(0xf5f7f9), 1).leftView(UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 40)), .always)
    }()
    
    private lazy var passWordField: UITextField = {
        UITextField(frame: CGRect(x: 20, y: self.userNameField.frame.maxY+10, width: ScreenWidth - 40, height: 40)).cornerRadius(5).placeholder("PassWord").delegate(self).tag(112).layerProperties(UIColor(0xf5f7f9), 1).leftView(UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 40)), .always)
    }()
    
    private lazy var login: UIButton = {
        UIButton(type: .custom).frame(CGRect(x: 20, y: self.passWordField.frame.maxY+40, width: ScreenWidth - 40, height: 45)).backgroundColor(UIColor(0x0066ff)).cornerRadius(10).title("Login", .normal).font(UIFont.systemFont(ofSize: 18, weight: .semibold)).addTargetFor(self, action: #selector(loginAction), for: .touchUpInside)
    }()
    
    private lazy var logRecord: PlaceHolderTextView = {
        PlaceHolderTextView(frame: CGRect(x: 20, y: self.login.frame.maxY+20, width: ScreenWidth - 40, height: ScreenHeight - self.login.frame.maxY - 40)).layerProperties(UIColor(0xf5f7f9), 1).cornerRadius(5).font(UIFont.systemFont(ofSize: 18, weight: .semibold)).isEditable(false)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubViews([self.logo,self.userNameField,self.passWordField,self.login,self.logRecord])
        self.logRecord.placeHolder = "Request Log"
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
    }

}

extension LoginViewController {
    
    @objc private func loginAction() {
        self.view.endEditing(true)
        guard let userName = self.userNameField.text,let passWord = self.passWordField.text,!userName.isEmpty,!passWord.isEmpty else { return }
        self.userName = userName.lowercased()
        self.passWord = passWord
        ProgressHUD.show("Resister user...", interaction: false)
        AgoraChatRequest.shared.registerToAppSever(userName: userName.lowercased(), passWord: passWord) {
            ProgressHUD.dismiss()
            self.loginHandler($0, $1)
        }
    }
    
    private func loginHandler(_ dic: Dictionary<String,Any>,_ code: Int) {
        if code == 200 {
            if let token = dic["accessToken"] as? String,let loginName = dic["chatUserName"] as? String,token.count > 0 {
                self.agoraChatLogin(loginName: loginName, token: token)
            }
        } else {
            if let code = dic["code"] as? String,code == "RES_USER_ALREADY_EXISTS" {
                guard let userName = self.userNameField.text,let passWord = self.passWordField.text,!userName.isEmpty,!passWord.isEmpty else { return }
                AgoraChatRequest.shared.loginToAppSever(userName: userName.lowercased(), passWord: passWord) { dic, code in
                    if let token = dic["accessToken"] as? String,let loginName = dic["chatUserName"] as? String,token.count > 0 {
                        self.agoraChatLogin(loginName: loginName, token: token)
                    }
                }
                return
            }
            let errorInfo = dic["errorInfo"] ?? ""
            self.logRecord.text! += "\n\(Date().z.dateString("yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ")):\(errorInfo)"
        }
    }
    
    private func agoraChatLogin(loginName: String,token:String) {
        ProgressHUD.show("Login user...", interaction: false)
        AgoraChatClient.shared().login(withUsername: loginName, agoraToken: token) { reponse, error in
            ProgressHUD.dismiss()
            if error == nil || error?.code.rawValue == 200 {
                self.userName = loginName.lowercased()
                self.logRecord.text! += "\n\(Date().z.dateString("yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ")):loginSuccess!"
                self.authE3(userName: loginName)
            } else {
                self.logRecord.text! += "\n\(Date().z.dateString("yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ")):\(error?.errorDescription ?? "")"
            }
        }
    }
    
    private func authE3(userName: String) {
        ProgressHUD.show("E3Authenticate...", interaction: false)
        AgoraChatRequest.shared.e3Authenticate(userName: userName) { token, error in
            ProgressHUD.dismiss()
            if token != nil {
                ProgressHUD.show("createEThree...", interaction: false)
                E3EncryptoManager.shared.createEThree(token,userName.lowercased())
                ProgressHUD.dismiss()
                ProgressHUD.show("E3 register...", interaction: false)
                E3EncryptoManager.shared.e3?.register(completion: { error in
                    ProgressHUD.dismiss()
                    DispatchQueue.main.async {
                        self.handleRegister(userName, error)
                    }
                })
            }
        }
    }
    
    private func handleRegister(_ userName: String,_ error: Error?) {
        if error == nil {
            do {
                try E3EncryptoManager.shared.card = E3EncryptoManager.shared.e3?.findUser(with: userName.lowercased()).startSync(timeout: 3).get()
            } catch {
                self.logRecord.text! += "\n\(Date().z.dateString("yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ")):\(error.localizedDescription)"
            }
            self.navigationController?.popViewController(animated: true)
        } else {
            self.logRecord.text! += "\n\(Date().z.dateString("yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ")):\(error?.localizedDescription ?? "")"
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}
