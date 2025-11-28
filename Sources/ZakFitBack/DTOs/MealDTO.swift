//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 27/11/2025.
//

import Vapor

struct MealDTO: Content {
    var type: String
    var date: Date?
}

struct MealCreateDTO: Content {
    var type: String
    var foods: [MealFoodInputDTO]
}

struct MealResponseDTO: Content {
    var id: UUID
    var type: String
    var date: Date
    var totalCalories: Int
    var totalProteins: Int
    var totalCarbs: Int
    var totalLipids: Int
    var foods: [MealFoodDTO] // liste des aliments
}

extension MealResponseDTO {
    init(from meal: Meal, foods: [MealFood]) throws {
        self.id = try meal.requireID()
        self.type = meal.typeMeal
        self.date = meal.dateMeal ?? Date() // timestamp par défaut
        self.totalCalories = meal.totalCalories
        self.totalProteins = meal.totalProteins
        self.totalCarbs = meal.totalCarbs
        self.totalLipids = meal.totalLipids
        
        self.foods = try foods.map { mf in
            let food = mf.food
            return MealFoodDTO(
                id: try food.requireID(),
                name: food.foodName,
                quantity: mf.quantityConsumed,
                calories: mf.caloriesCalculated,
                proteins: mf.proteinsCalculated,
                carbs: mf.carbsCalculated,
                lipids: mf.lipidsCalculated
            )
        }
    }
}

extension MealResponseDTO {
    init(from meal: Meal) {
        self.id = meal.id!
        self.type = meal.typeMeal
        self.date = meal.dateMeal ?? Date()
        self.totalCalories = meal.totalCalories
        self.totalProteins = meal.totalProteins
        self.totalCarbs = meal.totalCarbs
        self.totalLipids = meal.totalLipids
        self.foods = []
    }
}
