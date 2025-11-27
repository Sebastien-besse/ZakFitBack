//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 27/11/2025.
//

import Vapor


import Vapor

// DTO pour créer un meal (entrée utilisateur)
struct MealDTO: Content {
    var type: String
    var date: Date? // facultatif, pris par défaut via @Timestamp dans Meal
}

struct MealFoodInputDTO: Content {
    var foodID: UUID
    var quantity: Int
}

struct MealCreateDTO: Content {
    var type: String
    var foods: [MealFoodInputDTO]
}

// DTO pour un aliment dans un repas
struct MealFoodDTO: Content {
    var id: UUID
    var name: String
    var quantity: Int
    var calories: Int
    var proteins: Int
    var carbs: Int
    var lipids: Int
}

// DTO pour la réponse d’un repas complet avec ses aliments
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

// Extension pour créer le DTO à partir d’un Meal et de ses MealFood
extension MealResponseDTO {
    init(from meal: Meal, foods: [MealFood]) throws {
        self.id = try meal.requireID()
        self.type = meal.typeMeal
        self.date = meal.dateMeal ?? Date() // timestamp par défaut
        self.totalCalories = meal.totalCalories
        self.totalProteins = meal.totalProteins
        self.totalCarbs = meal.totalCarbs
        self.totalLipids = meal.totalLipids
        
        // Mapping des MealFood vers MealFoodDTO
        self.foods = try foods.map { mf in
            let food = mf.food // plus besoin de guard let
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
