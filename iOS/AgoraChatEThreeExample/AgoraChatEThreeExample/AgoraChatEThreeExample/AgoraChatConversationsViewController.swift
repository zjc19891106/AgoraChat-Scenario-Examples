//
//  AgoraChatE3ViewController.swift
//  AgoraChatEThreeExample
//
//  Created by 朱继超 on 2022/4/21.
//

import UIKit

final class AgoraChatConversationsViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,AgoraChatClientDelegate, AgoraChatManagerDelegate {
    
    private var toChatId = ""
    
    private var conversations = [AgoraChatConversation]()
    
    private lazy var conversationList: UITableView = {
        UITableView(frame: CGRect(x: 0, y: ZNavgationHeight, width: ScreenWidth, height: ScreenHeight-ZNavgationHeight), style: .plain).delegate(self).dataSource(self).tableFooterView(UIView()).rowHeight(60).separatorStyle(.none)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let datas = AgoraChatClient.shared().chatManager.getAllConversations() as? [AgoraChatConversation] else { return }
        self.conversations = datas
        self.loadGroup(self.conversations)
        // Do any additional setup after loading the view.
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addChat))
        self.view.addSubview(self.conversationList)
        AgoraChatClient.shared().add(self, delegateQueue: .main)
        AgoraChatClient.shared().chatManager.add(self, delegateQueue: .main)
    }
    
    deinit {
        AgoraChatClient.shared().removeDelegate(self)
        AgoraChatClient.shared().chatManager.remove(self)
    }
}

extension AgoraChatConversationsViewController {
    //MARK: - UITableViewDelegate&UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.conversations[safe: indexPath.row]
        var cell = tableView.dequeueReusableCell(withIdentifier: "AgoraChatE3ViewControllerCell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "AgoraChatE3ViewControllerCell")
        }
        cell?.textLabel?.text = item?.conversationId
        cell?.imageView?.image = UIImage(named: "default_avatar")
        cell?.accessoryType = .disclosureIndicator
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let to = self.conversations[safe: indexPath.row]?.conversationId ?? ""
        var key = E3EncryptoManager.shared.e3!.identity + to + "AgoraChat"
        key = key.lowercased()
        key = String(key.sorted())
        let group = E3EncryptoManager.shared.e3GroupMap[key.lowercased()]
        if group == nil {
            return
        }
        let VC = AgoraChatViewController.init(to,group!)
        VC.title = to
        if to.isEmpty {
            return
        }
        self.navigationController?.pushViewController(VC, animated: true)
    }
    
    @objc private func addChat() {
        let alert = UIAlertController(title: "Send to", message: nil, preferredStyle: .alert).addAlertTextField {
            $0.placeholder = "you want to chat userId!"
            $0.delegate = self
        }.addAlertAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            
        })).addAlertAction(UIAlertAction(title: "Confirm", style: .default, handler: { [weak self] _ in
            self?.createChat()
        }))
        self.navigationController?.present(alert, animated: true, completion: nil)
    }
    
    private func createChat() {
        //AgoraChatConversationType is group,create group use group's owner and id
        if self.toChatId.isEmpty {
            return
        }
        let item: AgoraChatConversation = AgoraChatClient.shared().chatManager.getConversation(self.toChatId, type: .chat, createIfNotExist: true)!
        var cards: FindUsersResult?
        var group: Group?
        do {
            cards = try E3EncryptoManager.shared.e3?.findUsers(with: [self.toChatId.lowercased()]).startSync(timeout: 5).get()
            var groupId = E3EncryptoManager.shared.e3!.identity + self.toChatId + "AgoraChat"
            item.ext = ["e3GroupInitiator":E3EncryptoManager.shared.e3!.identity.lowercased()]
            groupId = groupId.lowercased()
            groupId = String(groupId.sorted())
            group = try E3EncryptoManager.shared.e3?.createGroup(id: groupId, with: cards!).startSync(timeout: 5).get()
            E3EncryptoManager.shared.e3GroupMap[groupId.lowercased()] = group
        } catch {
            ProgressHUD.showError("createChat:\(error.localizedDescription)")
        }
        _ = E3EncryptoManager.shared.card
        cards?.forEach({
            E3EncryptoManager.shared.cards?[$0] = $1
        })
        let temp = self.conversations.filter { $0.conversationId == item.conversationId
        }
        if temp.count <= 0 {
            self.conversations.append(item)
            self.conversationList.reloadData()
        }
    }
    
    //MARK: - UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        self.toChatId = textField.text ?? ""
    }
    
    //MARK: - AgoraChatClientDelegate
    func tokenWillExpire(_ aErrorCode: Int32) {
        //Re-login required
        if aErrorCode == 110 {
            //Call the login related api to log in again than create e3
        }
    }

    func tokenDidExpire(_ aErrorCode: Int32) {
        //Re-login required
        //Call the login related api to log in again than create e3
    }
    //MARK: - AgoraChatManagerDelegate
    func messagesDidReceive(_ aMessages: [AgoraChatMessage]) {
        guard let datas = AgoraChatClient.shared().chatManager.getAllConversations() as? [AgoraChatConversation] else { return }
        self.loadGroup(datas)
        self.conversations.removeAll()
        self.conversations = datas
        self.conversationList.reloadData()
    }
    
    private func loadGroup(_ datas: [AgoraChatConversation]) {
        for item in datas {
            var groupId = E3EncryptoManager.shared.e3!.identity + item.conversationId! + "AgoraChat"
            groupId = String(groupId.lowercased().sorted())
            if E3EncryptoManager.shared.e3GroupMap[groupId] != nil{
                break
            }
            var group: Group?
            var cards: FindUsersResult?
            do {
                if let ext = item.ext,!ext.isEmpty,let initiator = ext["e3GroupInitiator"] as? String,!initiator.isEmpty {
                    cards = try E3EncryptoManager.shared.e3?.findUsers(with: [initiator]).startSync(timeout: 3).get()
                } else {
                    item.ext = ["e3GroupInitiator":item.conversationId.lowercased()]
                    cards = try E3EncryptoManager.shared.e3?.findUsers(with: [item.conversationId.lowercased()]).startSync(timeout: 3).get()
                }
            } catch {
                ProgressHUD.showError("receive message find user error:\(error.localizedDescription)")
            }
            do {
                group = try E3EncryptoManager.shared.e3?.loadGroup(id: groupId, initiator: cards!.first!.value).startSync(timeout: 5).get()
                E3EncryptoManager.shared.e3GroupMap[groupId] = group
            } catch {
                ProgressHUD.showError("load group error:\(error.localizedDescription)")
            }
            cards?.forEach({
                E3EncryptoManager.shared.cards![$0] = $1
            })
        }
    }
}
