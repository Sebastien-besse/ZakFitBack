//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 27/11/2025.
//

import Vapor
import Fluent

struct ActivityGoalController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let goals = routes.grouped("activity-goal")
        let protected = goals.grouped(JWTMiddleware())
        
        protected.post("create", use: createActivityGoal)
        protected.get("goal", use: getActivityGoals)
        protected.put("update",":id", use: updateActivityGoal)
    }
    
    // MARK: Créer un objectif
    @Sendable
    func createActivityGoal(req: Request) async throws -> ActivityGoalResponseDTO {
        let payload = try req.auth.require(UserPayload.self)
        let data = try req.content.decode(ActivityGoalDTO.self)
        
        let goal = ActivityGoal(
            typeActivity: data.typeActivity,
            trainingFrequency: data.trainingFrequency,
            caloriesBurned: data.caloriesBurned,
            durationOfSessions: data.durationOfSessions,
            userID: payload.id
        )
        
        try await goal.create(on: req.db)
        return try ActivityGoalResponseDTO(from: goal)
    }
    
    // MARK: Récupérer les objectifs d'un utilisateur
    @Sendable
    func getActivityGoals(req: Request) async throws -> [ActivityGoalResponseDTO] {
        let payload = try req.auth.require(UserPayload.self)
        let goals = try await ActivityGoal.query(on: req.db)
            .filter(\.$user.$id == payload.id)
            .all()
        
        return try goals.map { try ActivityGoalResponseDTO(from: $0) }
    }
    
    // MARK: Mettre à jour un objectif
    @Sendable
    func updateActivityGoal(req: Request) async throws -> ActivityGoalResponseDTO {
        let payload = try req.auth.require(UserPayload.self)
        guard let goalID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid goal ID")
        }
        
        guard let goal = try await ActivityGoal.find(goalID, on: req.db) else {
            throw Abort(.notFound, reason: "Goal not found")
        }
        
        guard goal.$user.id == payload.id else {
            throw Abort(.forbidden, reason: "Cannot modify another user's goal")
        }
        
        let data = try req.content.decode(ActivityGoalDTO.self)
        
        goal.typeActivity = data.typeActivity
        goal.trainingFrequency = data.trainingFrequency
        goal.caloriesBurned = data.caloriesBurned
        goal.durationOfSessions = data.durationOfSessions
        
        try await goal.update(on: req.db)
        return try ActivityGoalResponseDTO(from: goal)
    }
}
