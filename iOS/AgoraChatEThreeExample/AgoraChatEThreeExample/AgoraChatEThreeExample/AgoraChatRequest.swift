//
//  AgoraChatRequest.swift
//  AgoraChatEThreeExample
//
//  Created by 朱继超 on 2022/4/20.
//

import Foundation
@_exported import ZSwiftBaseLib

fileprivate let baseUrl = "https://a41.easemob.com"

fileprivate let appKey = "41117440#383391"

struct HTTPMethod: RawRepresentable, Equatable, Hashable {
    /// `CONNECT` method.
    public static let connect = HTTPMethod(rawValue: "CONNECT")
    /// `DELETE` method.
    public static let delete = HTTPMethod(rawValue: "DELETE")
    /// `GET` method.
    public static let get = HTTPMethod(rawValue: "GET")
    /// `HEAD` method.
    public static let head = HTTPMethod(rawValue: "HEAD")
    /// `OPTIONS` method.
    public static let options = HTTPMethod(rawValue: "OPTIONS")
    /// `PATCH` method.
    public static let patch = HTTPMethod(rawValue: "PATCH")
    /// `POST` method.
    public static let post = HTTPMethod(rawValue: "POST")
    /// `PUT` method.
    public static let put = HTTPMethod(rawValue: "PUT")
    /// `TRACE` method.
    public static let trace = HTTPMethod(rawValue: "TRACE")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}


final class AgoraChatRequest: NSObject,URLSessionDelegate {

    static var shared = AgoraChatRequest.init()
    
    private lazy var config: URLSessionConfiguration = {
        //MARK: - session config
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Content-Type":"application/json"]
        config.timeoutIntervalForRequest = 10
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return config
    }()
    
    private var session: URLSession?
    
    override init() {
        super.init()
        self.session = URLSession(configuration: self.config, delegate: self, delegateQueue: .main)
    }
    
    func constructRequest(method: HTTPMethod,
                          uri: String,
                          params: Dictionary<String,Any> ,
                          headers:[String : String],
                          callBack:@escaping ((Data?,HTTPURLResponse?,Error?) -> Void)) throws {

        guard let url = URL(string: baseUrl+uri) else {
            return
        }
        //MARK: - request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        urlRequest.httpMethod = method.rawValue
        self.session?.dataTask(with: urlRequest){
            if $2 == nil {
                callBack($0,($1 as! HTTPURLResponse),$2)
            } else {
                callBack(nil,nil,$2)
            }
        }.resume()
    }
    
    //MARK: - URLSessionDelegate
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential,credential)
        }
    }
}

extension AgoraChatRequest {
    func registerToAppSever(userName: String,passWord: String,callBack:@escaping ((Dictionary<String,Any>,Int) -> Void)) {
        do {
            try self.constructRequest(method: .post, uri: "/app/chat/user/register", params: ["userAccount":userName,"userPassword":passWord], headers: ["Content-Type":"application/json"]) { data,response,error in
                callBack(data?.z.toDictionary() ?? ["error":error?.localizedDescription ?? ""],0)
            }
        } catch {
            assert(false, "register error:\(error.localizedDescription)")
        }
    }
    
    func loginToAppSever(userName: String,passWord: String,callBack:@escaping ((Dictionary<String,Any>,Int) -> Void)) {
        do {
            try self.constructRequest(method: .post, uri: "/app/chat/user/login", params: ["userAccount":userName,"userPassword":passWord], headers: ["Content-Type":"application/json"]) { data,response,error in
                DispatchQueue.main.async {
                    if response?.statusCode == 200 {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "loginSuccess"), object: nil)
                    }
                    callBack(data?.z.toDictionary() ?? [:],response?.statusCode ?? 0)
                }
            }
        } catch {
            assert(false, "login error:\(error.localizedDescription)")
        }
    }
    
    func e3Authenticate(userName: String,callBack:@escaping ((String?,Error?) -> Void)) {
        do {
            try self.constructRequest(method: .post, uri: "/authenticate", params: ["identity":userName], headers: ["Content-Type":"application/json"]) { data,response,error in
                let token = data?.z.toDictionary()?["authToken"] as? String
                DispatchQueue.main.async {
                    callBack(token,nil)
                }
            }
        } catch {
            assert(false, "register error:\(error.localizedDescription)")
        }
    }
    
    func virgilToken(token: String,callBack:@escaping ((String?,Error?) -> Void)) {
        do {
            try self.constructRequest(method: .post, uri: "/virgil-jwt", params: ["identity":AgoraChatClient.shared().currentUsername ?? ""], headers: ["Content-Type":"application/json","Authorization": "Bearer " + token]) { data,response,error in
                let token = data?.z.toDictionary()?["virgilToken"] as? String
                DispatchQueue.main.async {
                    callBack(token,nil)
                }
            }
        } catch {
            assert(false, "register error:\(error.localizedDescription)")
        }
    }
}
