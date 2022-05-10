//
//  E3EncryptoManager.swift
//  AgoraChatEThreeExample
//
//  Created by 朱继超 on 2022/4/22.
//

import Foundation
@_exported import VirgilE3Kit
@_exported import VirgilSDK

class E3EncryptoManager {
    
    static let shared = E3EncryptoManager()
    
    let current = AgoraChatClient.shared().currentUsername ?? ""
    
    var e3: EThree?
    
    var card: Card?
    
    var cards: FindUsersResult? = FindUsersResult()
    
    var e3GroupMap = Dictionary<String,Group>()
    
    func createEThree(_ token: String?,_ userName: String) {
        let tokenCallback: EThree.RenewJwtCallback = { completion in
            guard let url = URL(string: "https://a41.easemob.com/virgil-jwt") else {
                return completion(nil, AppError.invalidUrl)
            }
            guard let authToken = token else {
                return completion(nil, AppError.notAuthenticated)
            }
            let headers = [
                "Content-Type": "application/json",
                "Authorization": "Bearer " + authToken
            ]
            let request = Request(url: url, method: .get, headers: headers)
            let connection = HttpConnection()
            guard let response = try? connection.send(request).startSync().get(),
                let body = response.body,
                let json = try? JSONSerialization.jsonObject(with: body, options: []) as? [String: Any],
                let jwtString = json["virgilToken"] as? String
                else {
                    return completion(nil, AppError.gettingJwtFailed)
            }
            print("virgilToken:\(jwtString)")
            completion(jwtString, nil)
        }
        var e3: EThree?
        do {
            e3 = try EThree(identity: userName, tokenCallback: tokenCallback)
        } catch {
            assert(true, "create EThree:\(error.localizedDescription)")
        }
        self.e3 = e3
    }
    
}
