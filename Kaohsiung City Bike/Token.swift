//
//  Token.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2022/11/30.
//  Copyright © 2022 Yang Tun-Kai. All rights reserved.
//

import Foundation

struct Token: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String
       
    private enum CodingKeys : String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}
