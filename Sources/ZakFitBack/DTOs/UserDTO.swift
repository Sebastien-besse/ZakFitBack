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
    var objectifHealth: String
    var diet: String
    var password: String
    
    func toModel() -> User{
        User(firstname: firstname, lastname: lastname, email: email, dateOfBirth: dateOfBirth, password: password, weight: weight, height: height, objectifHealth: objectifHealth, diet: diet)
    }
}

struct UserDTOAuth: Content{
    let email: String
    let password: String
}

struct UserResponse: Content{
    var firstname: String
    var lastname: String
    var email: String
    var dateOfBirth: Date
    var height: Int
    var weight: Int
    var objectifHealth: String
    var diet: String
}


extension UserResponse{
    init(from user: User) throws {
        self.firstname = user.firstname
        self.lastname = user.lastname
        self.email = user.email
        self.dateOfBirth = user.dateOfBirth
        self.height = user.height
        self.weight = user.weight
        self.objectifHealth = user.objectifHealth
        self.diet = user.diet
    }
}
