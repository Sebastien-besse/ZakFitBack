//
//  File.swift
//  ZakFitBack
//
//  Created by apprenant152 on 25/11/2025.
//

import Vapor
import Fluent

final class ActivityGoal: Model, Content, @unchecked Sendable{
    
    //Schéma correspondant à la table en base de données
    static let schema: String = "activity_goal"
    
    
    //Attribut
    @ID(custom: "activity_goal_id")
    var id: UUID?
    
    @Field(key: "type_activity")
    var typeActivity: String
    
    @Field(key: "training_frequency")
    var trainingFrequency: Int
    
    @Field(key: "calories_burned")
    var caloriesBurned: Int
    
    @Field(key: "duration_of_sessions")
    var durationOfSessions: Int
    
    // Relation
    @Parent(key: "user_id")
    var user: User
    
    
    //Constructeur
    init() {}
    
    init(id: UUID? = nil, typeActivity: String, trainingFrequency: Int, caloriesBurned: Int, durationOfSessions: Int, userID: UUID) {
        self.id = id
        self.typeActivity = typeActivity
        self.trainingFrequency = trainingFrequency
        self.caloriesBurned = caloriesBurned
        self.durationOfSessions = durationOfSessions
        self.$user.id = userID
    }
}
