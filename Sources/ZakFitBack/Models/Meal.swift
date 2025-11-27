//
//  File.swift
//  ZakFitBack
//
//  Created by apprenant152 on 25/11/2025.
//

import Vapor
import Fluent

final class Meal: Model, Content, @unchecked Sendable{
    
    static let schema: String = "meal"
    
    @ID(custom: "meal_id")
    var id: UUID?
    
    
    @Field(key: "type_meal")
    var typeMeal: String
    
    
    @Timestamp(key: "date_meal", on: .create)
    var dateMeal: Date?
    
    @Field(key: "total_calories")
    var totalCalories: Int
    
    
    @Field(key: "total_proteins")
    var totalProteins: Int
    
    
    @Field(key: "total_carbs")
    var totalCarbs: Int
    
    
    @Field(key: "total_lipids")
    var totalLipids: Int
    
    
    //Relation
    @Parent(key: "user_id")
    var user: User
    
    @Siblings(through: MealFood.self, from: \.$meal, to: \.$food)
    var foods: [Food]

    
    init() {}
    
    init(typeMeal: String, userID: UUID) {
        self.typeMeal = typeMeal
        self.totalCalories = 0
        self.totalProteins = 0
        self.totalCarbs = 0
        self.totalLipids = 0
        self.$user.id = userID
    }
    
    init(id: UUID? = nil, typeMeal: String, totalCalories: Int, totalProteins: Int, totalCarbs: Int, totalLipids: Int, userID: UUID){
        self.id = id
        self.typeMeal = typeMeal
        self.totalCalories = totalCalories
        self.totalProteins = totalProteins
        self.totalCarbs = totalCarbs
        self.totalLipids = totalLipids
        self.$user.id = userID
    }
}
