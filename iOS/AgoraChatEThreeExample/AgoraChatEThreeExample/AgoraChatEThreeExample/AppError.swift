//
//  AppError.swift
//  AgoraChatEThreeExample
//
//  Created by 朱继超 on 2022/4/22.
//

import Foundation

enum AppError: Error {
    case gettingJwtFailed
    case gettingChannelsListFailed
    case notAuthenticated
    case eThreeNotInitialized
    case invalidUrl
    case messagingNotInitialized
    case invalidResponse
}
