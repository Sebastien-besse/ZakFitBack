//
//  File.swift
//  ZakFitBack
//
//  Created by apprenant152 on 25/11/2025.
//

import Vapor
import Fluent

final class Food: Model, Content, @unchecked Sendable{
    
    // Schéma correspondant à la table en base de données
    static let schema: String = "food"
    
    // Attributs
    @ID(custom: "food_id")
    var id: UUID?
    
    @Field(key: "food_name")
    var foodName: String
    
    @Field(key: "calories")
    var calories: Int
    
    @Field(key: "proteins")
    var proteins: Int
    
    @Field(key: "carbs")
    var carbs: Int
    
    @Field(key: "lipids")
    var lipids: Int
    
    //Relation
    @Parent(key: "user_id")
    var user: User
    
    @Siblings(through: MealFood.self, from: \.$food, to: \.$meal)
    var meals: [Meal]
    
    
    //Constructeur
    init() {}
    
    init(id: UUID? = nil, foodName: String, calories: Int, proteins: Int, carbs: Int, lipids: Int, userID: UUID) {
        self.id = id
        self.foodName = foodName
        self.calories = calories
        self.proteins = proteins
        self.carbs = carbs
        self.lipids = lipids
        self.$user.id = userID
    }
    
}

