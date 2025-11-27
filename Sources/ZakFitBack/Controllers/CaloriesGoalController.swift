//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 27/11/2025.
//

import Vapor
import Fluent

struct CaloriesGoalController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let goals = routes.grouped("calories-goal")
        let protected = goals.grouped(JWTMiddleware())
        
        protected.post("create",use: createCaloriesGoal)
        protected.get("goal",use: getCaloriesGoal)
        protected.put(":id", use: updateCaloriesGoal)
    }
    
    // MARK: Créer un objectif nutritionnel
    @Sendable
    func createCaloriesGoal(req: Request) async throws -> CaloriesGoalResponseDTO {
        let payload = try req.auth.require(UserPayload.self)
        let data = try req.content.decode(CaloriesGoalDTO.self)
        
        let goal = CaloriesGoal(
            caloriesGoal: data.caloriesGoal,
            proteinsGoal: data.proteinsGoal,
            carbsGoal: data.carbsGoal,
            lipidsGoal: data.lipidsGoal,
            userID: payload.id
        )
        
        try await goal.create(on: req.db)
        return try CaloriesGoalResponseDTO(from: goal)
    }
    
    // MARK: Récupérer l'objectif nutritionnel de l'utilisateur
    @Sendable
    func getCaloriesGoal(req: Request) async throws -> CaloriesGoalResponseDTO {
        let payload = try req.auth.require(UserPayload.self)
        guard let goal = try await CaloriesGoal.query(on: req.db)
                .filter(\.$user.$id == payload.id)
                .first() else {
            throw Abort(.notFound, reason: "No nutrition goal found for this user.")
        }
        return try CaloriesGoalResponseDTO(from: goal)
    }
    
    // MARK: Mettre à jour l'objectif nutritionnel
    @Sendable
    func updateCaloriesGoal(req: Request) async throws -> CaloriesGoalResponseDTO {
        let payload = try req.auth.require(UserPayload.self)
        guard let goalID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid goal ID")
        }
        
        guard let goal = try await CaloriesGoal.find(goalID, on: req.db) else {
            throw Abort(.notFound, reason: "Goal not found")
        }
        
        guard goal.$user.id == payload.id else {
            throw Abort(.forbidden, reason: "Cannot modify another user's goal")
        }
        
        let data = try req.content.decode(CaloriesGoalDTO.self)
        goal.caloriesGoal = data.caloriesGoal
        goal.proteinsGoal = data.proteinsGoal
        goal.carbsGoal = data.carbsGoal
        goal.lipidsGoal = data.lipidsGoal
        
        try await goal.update(on: req.db)
        return try CaloriesGoalResponseDTO(from: goal)
    }
}

