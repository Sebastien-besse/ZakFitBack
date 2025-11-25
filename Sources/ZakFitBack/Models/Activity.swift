//
//  File.swift
//  ZakFitBack
//
//  Created by apprenant152 on 25/11/2025.
//

import Vapor
import Fluent

final class Activity: Model, Content, @unchecked Sendable{
    
    // Schéma correspondant à la table en base de données
    static let schema: String = "activity"
    
    // Attributs
    @ID(custom: "activity_id")
    var id: UUID?
    
    @Field(key: "type_activity")
    var activityName: String
    
    @Field(key: "dure_activity")
    var dureActivity: Int
    
    @Field(key: "calories_burned")
    var caloriesBurned: Int?
    
    @Timestamp(key: "date_activity", on: .create)
    var dateActivity: Date?
    
    // Relation
    @Parent(key: "user_id")
    var user: User
    
    // Constructeur
    init(){}
    
    init(id: UUID? = nil, activityName: String, dureActivity: Int, caloriesBurned: Int, userID: UUID) {
        self.id = id
        self.activityName = activityName
        self.dureActivity = dureActivity
        self.caloriesBurned = caloriesBurned
        self.$user.id = userID
    }
}
