//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 27/11/2025.
//

import Vapor

//// DTO pour un aliment dans un repas
//struct MealFoodDTO: Content {
//    var id: UUID
//    var name: String
//    var quantity: Int
//    var calories: Int
//    var proteins: Int
//    var carbs: Int
//    var lipids: Int
//}
//
//// DTO pour le repas complet
//struct MealResponseDTO: Content {
//    var id: UUID
//    var type: String
//    var date: Date
//    var totalCalories: Int
//    var totalProteins: Int
//    var totalCarbs: Int
//    var totalLipids: Int
//    var foods: [MealFoodDTO]
//}
//
//// Extension pour créer le DTO à partir d’un Meal
//extension MealResponseDTO {
//    init(from meal: Meal, foods: [MealFood]) throws {
//        self.id = try meal.requireID()
//        self.type = meal.typeMeal
//        self.date = meal.dateMeal ?? Date() // timestamp par défaut
//        self.totalCalories = meal.totalCalories
//        self.totalProteins = meal.totalProteins
//        self.totalCarbs = meal.totalCarbs
//        self.totalLipids = meal.totalLipids
//        
//        // Mapping des MealFood vers MealFoodDTO
//        self.foods = try foods.map { mf in
//            guard let food = mf.food else {
//                throw Abort(.internalServerError, reason: "Food not found for MealFood \(try mf.requireID())")
//            }
//            return MealFoodDTO(
//                id: try food.requireID(),
//                name: food.foodName,
//                quantity: mf.quantityConsumed,
//                calories: mf.caloriesCalculated,
//                proteins: mf.proteinsCalculated,
//                carbs: mf.carbsCalculated,
//                lipids: mf.lipidsCalculated
//            )
//        }
//    }
//}
