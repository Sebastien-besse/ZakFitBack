//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 27/11/2025.
//

import Vapor
import Fluent
import FluentSQL

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
        // Récupération du payload JWT
        let payload = try req.auth.require(UserPayload.self)
        
        // Vérifie si la DB est SQL
        guard let sql = req.db as? (any SQLDatabase) else {
            throw Abort(.internalServerError, reason: "La base de donnée n'est pas SQL")
        }
        
        // Exécution de la requête SQL en dur avec bind
        let rows = try await sql.raw("""
            SELECT id,
                   user_id,
                   exercise_id,
                   target,
                   created_at,
                   updated_at
            FROM activity_goals
            WHERE user_id = \(bind: payload.id)
        """).all(decoding: ActivityGoalResponseDTO.self)
        
        return rows
    }
    // MARK: Mettre à jour un objectif
    @Sendable
    func updateActivityGoal(req: Request) async throws -> ActivityGoalResponseDTO {
        let payload = try req.auth.require(UserPayload.self)
        guard let goalID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "L'id de l'objectif est invalide")
        }
        
        guard let goal = try await ActivityGoal.find(goalID, on: req.db) else {
            throw Abort(.notFound, reason: "Objectif non trouvé")
        }
        
        guard goal.$user.id == payload.id else {
            throw Abort(.forbidden, reason: "Ne peut pas modifier l’objectif d’un autre utilisateur")
        }
        
        // Décodage du body JSON envoyé côté client
        let data = try req.content.decode(ActivityGoalDTO.self)
        
        goal.typeActivity = data.typeActivity
        goal.trainingFrequency = data.trainingFrequency
        goal.caloriesBurned = data.caloriesBurned
        goal.durationOfSessions = data.durationOfSessions
        
        //Sauvegarde des modifications
        try await goal.update(on: req.db)
        return try ActivityGoalResponseDTO(from: goal)
    }
}
