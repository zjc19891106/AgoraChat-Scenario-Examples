//
//  ViewController.swift
//  AgoraChatEThreeExample
//
//  Created by 朱继超 on 2022/4/20.
//

import UIKit

final class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    var data = ["Register than login","LogOut","E3EncryptChats","ConsoleLog"]
    
    lazy var functionList: UITableView = {
        UITableView(frame: CGRect(x: 0, y: ZNavgationHeight, width: ScreenWidth, height: ScreenHeight-ZNavgationHeight), style: .plain).delegate(self).dataSource(self).tableFooterView(UIView()).rowHeight(50)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let userName = AgoraChatClient.shared().currentUsername,userName.count > 0 {
            self.data.removeFirst()
        }
        self.view.addSubViews([self.functionList])
        self.view.backgroundColor = .white
        self.refreshHeader()
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "loginSuccess"), object: nil, queue: .main) { _ in
            self.data.removeAll { $0 == "Register than login" }
            self.functionList.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshHeader()
    }

}

extension ViewController {
    private func refreshHeader() {
        if !(AgoraChatClient.shared().currentUsername ?? "").isEmpty {
            self.functionList.tableHeaderView = UILabel(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 30)).text("current user is:\(AgoraChatClient.shared().currentUsername ?? "")").textAlignment(.center)
        }
    }
    //MARK: - UITableViewDelegate&UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "666")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "666")
        }
        let text = self.data[safe: indexPath.row]
        cell?.textLabel?.text = text
        cell?.accessoryType = (text == "LogOut" ? .none:.disclosureIndicator)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var VC: UIViewController?
        let text = self.data[safe: indexPath.row]
        switch text {
        case "Register than login":
            VC = LoginViewController.init()
        case "LogOut":
            self.logoutAction()
        case "E3EncryptChats":
            VC = AgoraChatConversationsViewController.init()
        case "ConsoleLog":
            VC = ConsoleLogViewController.init()
        default:
            VC = nil
        }
        if VC != nil {
            VC?.title = self.data[safe: indexPath.row]
            self.navigationController?.pushViewController(VC!, animated: true)
        }
    }
    
    private func logoutAction() {
        if let user = AgoraChatClient.shared().currentUsername,!user.isEmpty {
            return
        }
        AgoraChatClient.shared().logout(true)
        self.functionList.tableHeaderView = nil
        do {
            try E3EncryptoManager.shared.e3?.cleanUp()
        } catch {
            ProgressHUD.showError(error.localizedDescription)
        }
        self.data.insert("Register than login", at: 0)
        self.functionList.reloadData()
    }
    
    
}
