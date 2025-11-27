//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 27/11/2025.
//

import Vapor
import Fluent

struct MealController:  RouteCollection{
    func boot(routes: any RoutesBuilder) throws {
        // Je regroupe mes routes
        let meal = routes.grouped("meal")
        
        // Groupe de routes nécessitant le middleware JWT
        let protectedRoutes = meal.grouped(JWTMiddleware())
        protectedRoutes.post("create", use: createMeal)
        protectedRoutes.get("meals", use: getMeals)
        protectedRoutes.post("createwithfood", use: createMealWithFoods)
    }
    
    //MARK: Création d'un repas
    @Sendable
    func createMeal(req: Request) async throws -> MealResponseDTO {
        let payload = try req.auth.require(UserPayload.self)

        let data = try req.content.decode(MealDTO.self)

        // Validation simple serveur
        guard !data.type.isEmpty else {
            throw Abort(.badRequest, reason: "Meal type cannot be empty.")
        }

        let meal = Meal(
            typeMeal: data.type,
            userID: payload.id
        )

        try await meal.create(on: req.db)

        return MealResponseDTO(from: meal)
    }
    
    
    //MARK: Récuperer les repas de l'utilisateur
    @Sendable
    func getMeals(req: Request) async throws -> [MealResponseDTO] {
        let payload = try req.auth.require(UserPayload.self)

        // Démarrer la requête filtrée par userID
        var query = Meal.query(on: req.db)
            .filter(\.$user.$id == payload.id)

        // Filtrer par date si fourni (yyyy-MM-dd)
        if let dateString = req.query[String.self, at: "date"] {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateString) {
                let calendar = Calendar.current
                let start = calendar.startOfDay(for: date)
                let end = calendar.date(byAdding: .day, value: 1, to: start)!
                query = query.filter(\.$dateMeal >= start)
                             .filter(\.$dateMeal < end)
            }
        }

        // Filtrer par type de repas si fourni
        if let type = req.query[String.self, at: "type"] {
            query = query.filter(\.$typeMeal == type)
        }

        // Appliquer tri si demandé
        if let sort = req.query[String.self, at: "sort"] {
            switch sort.lowercased() {
            case "date":
                query = query.sort(\.$dateMeal, .descending)
            case "type":
                query = query.sort(\.$typeMeal, .ascending)
            case "calories":
                query = query.sort(\.$totalCalories, .descending)
            default:
                break
            }
        }

        let meals = try await query.all()

        // Pour chaque repas, récupérer les MealFood associés
        var result: [MealResponseDTO] = []
        for meal in meals {
            let mealFoods = try await MealFood.query(on: req.db)
                .filter(\.$meal.$id == meal.requireID())
                .with(\.$food)
                .all()
            result.append(try MealResponseDTO(from: meal, foods: mealFoods))
        }

        return result
    }
    
    
    @Sendable
    func createMealWithFoods(req: Request) async throws -> MealResponseDTO {
        let payload = try req.auth.require(UserPayload.self)
        let data = try req.content.decode(MealCreateDTO.self)

        // Validation
        guard !data.type.isEmpty else {
            throw Abort(.badRequest, reason: "Meal type cannot be empty.")
        }
        guard !data.foods.isEmpty else {
            throw Abort(.badRequest, reason: "Meal must contain at least one food.")
        }

        // Création du repas "vide"
        let meal = Meal(typeMeal: data.type, userID: payload.id)
        try await meal.create(on: req.db)

        var totalCalories = 0
        var totalProteins = 0
        var totalCarbs = 0
        var totalLipids = 0

        for item in data.foods {
            guard let food = try await Food.find(item.foodID, on: req.db) else {
                throw Abort(.notFound, reason: "Food with ID \(item.foodID) not found.")
            }

            let factor = Double(item.quantity) / 100.0
            let cals = Int(Double(food.calories) * factor)
            let prots = Int(Double(food.proteins) * factor)
            let carbs = Int(Double(food.carbs) * factor)
            let lipids = Int(Double(food.lipids) * factor)

            totalCalories += cals
            totalProteins += prots
            totalCarbs += carbs
            totalLipids += lipids

            let mealFood = MealFood(
                quantityConsumed: item.quantity,
                caloriesCalculated: cals,
                proteinsCalculated: prots,
                carbsCalculated: carbs,
                lipidsCalculated: lipids,
                mealID: try meal.requireID(),
                foodID: try food.requireID()
            )
            try await mealFood.create(on: req.db)
        }

        meal.totalCalories = totalCalories
        meal.totalProteins = totalProteins
        meal.totalCarbs = totalCarbs
        meal.totalLipids = totalLipids
        try await meal.update(on: req.db)

        //Récupérer tous les MealFood liés pour le DTO
        let mealFoods = try await MealFood.query(on: req.db)
            .filter(\.$meal.$id == meal.requireID())
            .with(\.$food)
            .all()

        return try MealResponseDTO(from: meal, foods: mealFoods)
    }
    
    
}
