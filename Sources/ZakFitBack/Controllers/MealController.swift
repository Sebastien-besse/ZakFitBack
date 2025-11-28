//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 27/11/2025.
//

import Vapor
import Fluent

struct MealController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {

        // Je regroupe toutes les routes du module Meal
        let meal = routes.grouped("meal")
        
        // Toutes ces routes nécessitent un utilisateur connecté via JWT
        let protectedRoutes = meal.grouped(JWTMiddleware())

        // Création d’un repas sans aliment
        protectedRoutes.post("create", use: createMeal)

        // Récupération des repas avec filtres
        protectedRoutes.get("meals", use: getMeals)

        // Création d’un repas + ses aliments en une seule requête
        protectedRoutes.post("createwithfood", use: createMealWithFoods)
    }

    //MARK: Création d’un repas simple
    @Sendable
    func createMeal(req: Request) async throws -> MealResponseDTO {

        // Récupération de l'utilisateur connecté via JWT
        let payload = try req.auth.require(UserPayload.self)

        // Récupération des données envoyées par le front
        let data = try req.content.decode(MealDTO.self)

        // Petite validation serveur
        guard !data.type.isEmpty else {
            throw Abort(.badRequest, reason: "Le type de repas ne peut pas être vide")
        }

        // Création du repas
        let meal = Meal(
            typeMeal: data.type,
            userID: payload.id
        )

        try await meal.create(on: req.db)

        return MealResponseDTO(from: meal)
    }

    //MARK: Récupérer les repas de l’utilisateur avec les filtres
    @Sendable
    func getMeals(req: Request) async throws -> [MealResponseDTO] {

        let payload = try req.auth.require(UserPayload.self)

        var query = Meal.query(on: req.db)
            .filter(\.$user.$id == payload.id)

        // Filtre date via DateUtils
        if let dateString = req.query[String.self, at: "date"],
           let date = DateUtils.defaultFormatter.date(from: dateString) {

            let start = DateUtils.startOfDay(date)
            let end = DateUtils.endOfDay(date)

            query = query.filter(\.$dateMeal >= start)
                         .filter(\.$dateMeal < end)
        }

        // Filtre type
        if let type = req.query[String.self, at: "type"] {
            query = query.filter(\.$typeMeal == type)
        }

        // Tri
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

        var result: [MealResponseDTO] = []

        // Rendu final
        for meal in meals {
            let mealFoods = try await MealFood.query(on: req.db)
                .filter(\.$meal.$id == meal.requireID())
                .with(\.$food)
                .all()

            result.append(try MealResponseDTO(from: meal, foods: mealFoods))
        }

        return result
    }

    //MARK: Création d’un repas avec plusieurs aliments
    @Sendable
    func createMealWithFoods(req: Request) async throws -> MealResponseDTO {

        let payload = try req.auth.require(UserPayload.self)
        let data = try req.content.decode(MealCreateDTO.self)

        // Validations basiques
        guard !data.type.isEmpty else {
            throw Abort(.badRequest, reason: "Le type de repas ne peut pas être vide.")
        }
        guard !data.foods.isEmpty else {
            throw Abort(.badRequest, reason: "Le repas doit contenir au moins un aliment.")
        }

        // Création du repas vide
        let meal = Meal(typeMeal: data.type, userID: payload.id)
        try await meal.create(on: req.db)

        // Variables pour calculer les nutriments totaux
        var totalCalories = 0
        var totalProteins = 0
        var totalCarbs = 0
        var totalLipids = 0

        // Pour chaque aliment envoyé par le front
        for item in data.foods {

            // Je vérifie que l’aliment existe
            guard let food = try await Food.find(item.foodID, on: req.db) else {
                throw Abort(.notFound, reason: "L’aliment avec l’id \(item.foodID) est introuvable")
            }

            // Calcul du ratio selon la quantité (base = 100g)
            let factor = Double(item.quantity) / 100.0

            let cals = Int(Double(food.calories) * factor)
            let prots = Int(Double(food.proteins) * factor)
            let carbs = Int(Double(food.carbs) * factor)
            let lipids = Int(Double(food.lipids) * factor)

            totalCalories += cals
            totalProteins += prots
            totalCarbs += carbs
            totalLipids += lipids

            // Création de l’association MealFood
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

        // Mise à jour des totaux dans le repas
        meal.totalCalories = totalCalories
        meal.totalProteins = totalProteins
        meal.totalCarbs = totalCarbs
        meal.totalLipids = totalLipids

        try await meal.update(on: req.db)

        // Je recharge les MealFood pour renvoyer un DTO complet
        let mealFoods = try await MealFood.query(on: req.db)
            .filter(\.$meal.$id == meal.requireID())
            .with(\.$food)
            .all()

        return try MealResponseDTO(from: meal, foods: mealFoods)
    }
}
