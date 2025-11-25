//
//  File.swift
//  ZakFitBack
//
//  Created by apprenant152 on 25/11/2025.
//

import Vapor
import Fluent

final class CaloriesGoal: Model, Content, @unchecked Sendable{
    
    // Schéma correspondant à la table en base de données
    static let schema: String = "calories_goal"
    
    //Attribut
    @ID(custom: "calories_goal_id")
    var id: UUID?
    
    @Field(key: "calories_goal")
    var caloriesGoal: Int
    
    @Field(key: "proteins_goal")
    var proteinsGoal: Int
    
    @Field(key: "carbs_goal")
    var carbsGoal: Int
    
    @Field(key: "lipids_goal")
    var lipidsGoal: Int
    
    @Timestamp(key: "date_goal", on: .create)
    var dateGoal: Date?
    
    // Relation
    @Parent(key: "user_id")
    var user: User
    
    
    //Constructeur
    init() {}
    
    init(id: UUID? = nil, caloriesGoal: Int, proteinsGoal: Int, carbsGoal: Int, lipidsGoal: Int, userID: UUID) {
        self.id = id
        self.caloriesGoal = caloriesGoal
        self.proteinsGoal = proteinsGoal
        self.carbsGoal = carbsGoal
        self.lipidsGoal = lipidsGoal
        self.$user.id = userID
    }
}

