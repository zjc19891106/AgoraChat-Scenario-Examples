//
//  AgoraChatViewController.swift
//  AgoraChatEThreeExample
//
//  Created by 朱继超 on 2022/4/21.
//

import UIKit
import QuickLook

final class AgoraChatViewController: UIViewController,UITableViewDelegate,UITableViewDataSource, AgoraChatClientDelegate, AgoraChatManagerDelegate, UITextFieldDelegate,QLPreviewControllerDelegate,QLPreviewControllerDataSource {
    
    private var filePath = ""
    
    private var heightMap = Dictionary<String,CGFloat>()
    
    private var messages: [AgoraChatMessage] = [AgoraChatMessage]()
    
    private var conversation: AgoraChatConversation?
    
    private var group: Group?
    
    private lazy var messagesList: UITableView = {
        UITableView(frame: CGRect(x: 0, y: ZNavgationHeight, width: ScreenWidth, height: ScreenHeight-ZNavgationHeight-40-CGFloat(ZBottombarHeight)), style: .plain).delegate(self).dataSource(self).tableFooterView(UIView()).separatorStyle(.none)
    }()
    
    private lazy var messageField: UITextField = {
        UITextField(frame: CGRect(x: 2, y: Int(ScreenHeight) - 40 - ZBottombarHeight, width: Int(ScreenWidth) - 4, height: 40)).delegate(self).layerProperties(.systemBlue, 2).placeholder("Send Text Message").cornerRadius(5).leftView(UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 40)), .always)
    }()
    
    convenience init(_ conversationId: String,_ group: Group) {
        self.init()
        self.conversation = AgoraChatClient.shared().chatManager.getConversationWithConvId(conversationId)
        let messages = self.conversation?.loadMessagesStart(fromId: "", count: 50, searchDirection: .up) ?? []
        self.group = group
        AgoraChatCell.group = self.group
        self.loadMessagerCard(messages)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubViews([self.messagesList,self.messageField])
        self.messageField.returnKeyType = .send
        AgoraChatClient.shared().add(self, delegateQueue: .main)
        AgoraChatClient.shared().chatManager.add(self, delegateQueue: .main)
        NotificationCenter.default.addObserver(self, selector: #selector(showKeyboard(notify:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        // Do any additional setup after loading the view.
    }
    
    deinit {
        AgoraChatClient.shared().removeDelegate(self)
        AgoraChatClient.shared().chatManager.remove(self)
        NotificationCenter.default.removeObserver(self)
    }
}

extension AgoraChatViewController {
    
    private func loadMessagerCard(_ messages: [AgoraChatMessage]) {
        var users = [String]()
        for message in messages {
            if !users.contains(message.from) {
                users.append(message.from)
            }
        }
        users.append(E3EncryptoManager.shared.e3!.identity)
        var cards: FindUsersResult?
        if users.count > 0 {
            do {
                cards = try E3EncryptoManager.shared.e3?.findUsers(with: users).startSync(timeout: 5).get()
            } catch {
                ProgressHUD.showError("chat find user error:\(error.localizedDescription)")
            }
        }
        cards?.forEach({
            E3EncryptoManager.shared.cards?[$0] = $1
        })
        for message in messages {
            if self.heightMap[message.messageId] ?? 0 <= 0 {
                self.heightMap[message.messageId] = AgoraChatCell.contentHeight(message)+52
            }
        }
        self.messages.append(contentsOf: messages)
    }
    
    //MARK: - UITableViewDelegate&UITableViewDataSource
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let message: AgoraChatMessage = self.messages[safe: indexPath.row]!
        return self.heightMap[message.messageId] ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message: AgoraChatMessage = self.messages[safe: indexPath.row]!
        var cell = tableView.dequeueReusableCell(withIdentifier: "AgoraChatViewControllerCell") as? AgoraChatCell
        if cell == nil {
            cell = AgoraChatCell(style: .subtitle, reuseIdentifier: "AgoraChatViewControllerCell")
        }
        cell?.updateLayout(message: message)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let message: AgoraChatMessage = self.messages[safe: indexPath.row]!
        switch message.body.type {
        case .image,.video,.voice,.file:
            AgoraChatClient.shared().chatManager.downloadMessageAttachment(message, progress: nil) { msg, error in
                if error == nil,let body = message.body as? AgoraChatFileMessageBody {
                    self.quickLookFile(filePath: body.localPath)
                }
            }
        default:
            break
        }
    }
    
    private func quickLookFile(filePath: String) {
        if filePath.isEmpty {
            return
        }
        self.filePath = filePath
        let quick = QLPreviewController.init()
        quick.delegate = self
        quick.dataSource = self
        quick.reloadData()
        quick.refreshCurrentPreviewItem()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
            self.present(quick, animated: true, completion: nil)
        }
    }
    
    //MARK: - QLPreviewControllerDelegate&QLPreviewControllerDataSource
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return URL(fileURLWithPath: self.filePath) as QLPreviewItem
    }
    
    //MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        if E3EncryptoManager.shared.cards![E3EncryptoManager.shared.e3!.identity] == nil {
            return false
        }
        guard var text = textField.text else { return false }
        do {
            text = try self.group?.encrypt(text: text) ?? ""
        } catch {
            ProgressHUD.showError("chat send message error:\(error.localizedDescription)")
        }
        self.sendTextMessage(text)
        textField.text = ""
        return true
    }
    
    private func sendTextMessage(_ text: String) {
        let to = self.conversation?.conversationId ?? ""
        let message = AgoraChatMessage(conversationID: to, from: AgoraChatClient.shared().currentUsername!, to: to, body: AgoraChatTextMessageBody(text: text), ext: [:])
        AgoraChatClient.shared().chatManager.send(message, progress: nil) { sendMessage, error in
            if let msg = sendMessage,error == nil {
                self.loadMessagerCard([msg])
                self.messagesList.reloadData()
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        self.keyboardRaiseAnimation()
    }
    
    //MARK: - AgoraChatClientDelegate
    
    //MARK: - AgoraChatManagerDelegate
    func messagesDidReceive(_ aMessages: [Any]!) {
        guard let messages = aMessages as? [AgoraChatMessage] else { return }
        self.loadMessagerCard(messages)
        DispatchQueue.main.async {
            self.messagesList.reloadData()
            self.messagesList.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: .bottom, animated: true)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    private func keyboardRaiseAnimation() {
        UIView.animate(withDuration: 0.25) {
            self.messageField.frame = CGRect(x: 10, y: Int(ScreenHeight) - 40 - ZBottombarHeight, width: Int(ScreenWidth) - 20, height: 40)
        }
    }
    
    @objc private func showKeyboard(notify: Notification) {
        guard let frame = notify.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        UIView.animate(withDuration: 0.25) {
            self.messageField.frame = CGRect(x: 10, y: Int(ScreenHeight) - 40 - Int(frame.cgRectValue.height), width: Int(ScreenWidth) - 20, height: 40)
        }
    }
}
