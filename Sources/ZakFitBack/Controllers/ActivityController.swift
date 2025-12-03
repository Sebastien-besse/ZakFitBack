//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 26/11/2025.
//

import Vapor
import Fluent
import JWT

struct ActivityController: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        let activity = routes.grouped("activity")
        let protectedRoutes = activity.grouped(JWTMiddleware())
        protectedRoutes.post("create", use: createActivity)
        protectedRoutes.get("activities", use: getActivities)
        protectedRoutes.put("update",":id", use: updateActivity)
        protectedRoutes.delete("delete", ":id", use: deleteActivity)
        protectedRoutes.get("exercises", use: getAllExercises)
    }

    // MARK: - Créer une activité
    @Sendable
    func createActivity(req: Request) async throws -> ActivityResponse {
        let payload = try req.auth.require(UserPayload.self)
        guard let user = try await User.find(payload.id, on: req.db) else {
            throw Abort(.notFound)
        }

        let dto = try req.content.decode(ActivityDTO.self)
        guard let exercise = try await Exercise.find(dto.exerciseID, on: req.db) else {
            throw Abort(.notFound, reason: "Exercise not found.")
        }

        let activity = dto.toModel(exercise: exercise, userID: user.id!)
        try await activity.create(on: req.db)

        return ActivityResponse(from: activity, exercise: exercise)
    }

    // MARK: - Récupérer toutes les activités de l'utilisateur
    @Sendable
    func getActivities(req: Request) async throws -> [ActivityResponse] {
        let payload = try req.auth.require(UserPayload.self)
        let activities = try await Activity.query(on: req.db)
            .filter(\.$user.$id == payload.id)
            .with(\.$exercise) // Jointure avec Exercise
            .all()

        return activities.map { ActivityResponse(from: $0, exercise: $0.$exercise.value!) }
    }

    // MARK: - Endpoint public pour récupérer tous les exercices
    func getAllExercises(req: Request) async throws -> [ExerciseDTO] {
        let exos = try await Exercise.query(on: req.db).all()
        return exos.compactMap { ex in
            guard let id = ex.id else { return nil }
            return ExerciseDTO(
                id: id,
                name: ex.name,
                type: ex.type,
                defaultCaloriesPerMin: ex.defaultCaloriesPerMin ?? 5,
                motivationMessage: ex.motivationMessage
            )
        }
    }

    // MARK: - Mettre à jour une activité
    @Sendable
    func updateActivity(req: Request) async throws -> ActivityResponse {
        let payload = try req.auth.require(UserPayload.self)
        guard let activityID = req.parameters.get("id", as: UUID.self),
              let activity = try await Activity.find(activityID, on: req.db) else {
            throw Abort(.notFound, reason: "Activity not found.")
        }

        guard activity.$user.id == payload.id else {
            throw Abort(.forbidden, reason: "You are not allowed to modify this activity.")
        }

        let data = try req.content.decode(UpdateActivityDTO.self)
        var exercise: Exercise? = nil

        if let newExerciseID = data.exerciseID {
            guard let e = try await Exercise.find(newExerciseID, on: req.db) else {
                throw Abort(.notFound, reason: "Exercise not found.")
            }
            activity.$exercise.id = e.id!
            exercise = e
        } else {
            exercise = try await activity.$exercise.get(on: req.db)
        }

        if let duration = data.duration { activity.duration = duration }
        if let date = data.date { activity.dateActivity = date }

        if let calories = data.caloriesBurned {
            activity.caloriesBurned = calories
        } else if let exercise = exercise {
            activity.caloriesBurned = (exercise.defaultCaloriesPerMin ?? 5) * activity.duration
        }

        try await activity.update(on: req.db)
        return ActivityResponse(from: activity, exercise: exercise!)
    }

    // MARK: - Supprimer une activité
    @Sendable
    func deleteActivity(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        guard let activityID = req.parameters.get("id", as: UUID.self),
              let activity = try await Activity.find(activityID, on: req.db) else {
            throw Abort(.notFound, reason: "Activity not found.")
        }

        guard activity.$user.id == payload.id else {
            throw Abort(.forbidden, reason: "You are not allowed to delete this activity.")
        }

        try await activity.delete(on: req.db)
        return .ok
    }
}
