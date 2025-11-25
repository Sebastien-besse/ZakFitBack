//
//  File.swift
//  ZakFitBack
//
//  Created by apprenant152 on 25/11/2025.
//

import Vapor
import Fluent

final class MealFood: Model, Content, @unchecked Sendable{
    
    static let schema: String = "meal_food"
    
    @ID(custom: "meal_food_id")
    var id: UUID?
    
    @Field(key: "quantity_consumed")
    var quantityConsumed: Int
    
    @Field(key: "calories_calculated")
    var caloriesCalculated: Int
    
    @Field(key: "proteins_calculated")
    var proteinsCalculated: Int
    
    @Field(key: "carbs_calculated")
    var carbsCalculated: Int
    
    @Field(key: "lipids_calculated")
    var lipidsCalculated: Int
    
    @Parent(key: "meal_id")
    var meal: Meal

    @Parent(key: "food_id")
    var food: Food

    init() {}
    
    init(id: UUID? = nil, quantityConsumed: Int, caloriesCalculated: Int, proteinsCalculated: Int, carbsCalculated: Int, lipidsCalculated: Int, mealID: UUID, foodID: UUID) {
        self.id = id
        self.quantityConsumed = quantityConsumed
        self.caloriesCalculated = caloriesCalculated
        self.proteinsCalculated = proteinsCalculated
        self.carbsCalculated = carbsCalculated
        self.lipidsCalculated = lipidsCalculated
        self.$meal.id = mealID
        self.$food.id = foodID
    }
    
}
