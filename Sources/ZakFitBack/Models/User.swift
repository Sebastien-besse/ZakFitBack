//
//  File.swift
//  ZakFitBack
//
//  Created by apprenant152 on 25/11/2025.
//

import Vapor
import Fluent

final class User: Model, Content, @unchecked Sendable{
    
    // Schéma correspondant à la table en base de données
    static let schema: String = "user"
    
    // Attributs
    @ID(custom: "user_id")
    var id: UUID?
    
    @Field(key: "firstname")
    var firstname: String
    
    @Field(key: "lastname")
    var lastname: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "date_of_birth")
    var dateOfBirth: Date
    
    @Field(key: "password")
    var password: String
    
    @Field(key: "weight")
    var weight: Int
    
    @Field(key: "height")
    var height: Int
    
    @Field(key: "objectif_health")
    var objectifHealth: String

    @Field(key: "diet")
    var diet: String
    
    // Relation
    @Children(for: \.$user)
    var activities: [Activity]
    
    @Children(for: \.$user)
    var meals: [Meal]
    
    
    // Constructeur
    init() {}
    
    init(id: UUID? = nil, firstname: String, lastname: String, email: String, dateOfBirth: Date, password: String, weight: Int, height: Int, objectifHealth: String, diet: String) {
        self.id = id
        self.firstname = firstname
        self.lastname = lastname
        self.email = email
        self.dateOfBirth = dateOfBirth
        self.password = password
        self.weight = weight
        self.height = height
        self.objectifHealth = objectifHealth
        self.diet = diet
    }
 
}
