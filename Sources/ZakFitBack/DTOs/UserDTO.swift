//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 25/11/2025.
//

import Vapor

struct UserDTO: Content{
    var firstname: String
    var lastname: String
    var email: String
    var dateOfBirth: Date
    var height: Int
    var weight: Int
    var password: String
}

struct UserDTOAuth{
    let email: String
    let password: String
}
