//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 26/11/2025.
//

import Vapor
import Fluent
import JWT

struct ActivityController: RouteCollection{
    
    // Définition des routes
    func boot(routes: any RoutesBuilder) throws {
        // Je regroupe mes routes
        let activity = routes.grouped("activity")
        
        // Groupe de routes nécessitant le middleware JWT
        let protectedRoutes = activity.grouped(JWTMiddleware())
        protectedRoutes.post("create", use: createActivity)
        protectedRoutes.get("activities", use: getActivities)
        protectedRoutes.put("update",":id", use: updateActivity)
        protectedRoutes.delete("delete", ":id", use: deleteActivity)
    }
    
    //MARK: Créer une activité
    @Sendable
    func createActivity(req: Request) async throws -> ActivityResponse{
        // Je verifie l'auth
        let payload = try req.auth.require(UserPayload.self)
        
        guard (try await User.find(payload.id, on: req.db)) != nil else {
            throw Abort (.notFound)
        }
        // je decode le contenu json envoyé par le client
        let activityDTO = try req.content.decode(ActivityDTO.self).toModel(userID: payload.id)
        
        // J'envoie en base de données les données de l'activité
        try await activityDTO.create(on: req.db)
        
        // Je retourne un model contenant les données de l'activité
        return try ActivityResponse(from: activityDTO)
        
    }
    

    //MARK: Récupération de tout les activités de l'utilisateur
    // MARK: Récupération de toutes les activités de l'utilisateur
    @Sendable
    func getActivities(req: Request) async throws -> [ActivityResponse] {
        let payload = try req.auth.require(UserPayload.self)

        // Préparer le calendrier UTC
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        // Base de la requête filtrée par utilisateur
        var query = Activity.query(on: req.db)
            .filter(\.$user.$id == payload.id)

        // MARK: - Filtres simples
        if let type = req.query[String.self, at: "type"] {
            query = query.filter(\.$activityName == type)
        }
        if let minDuration = req.query[Int.self, at: "minDuration"] {
            query = query.filter(\.$dureActivity >= minDuration)
        }
        if let maxDuration = req.query[Int.self, at: "maxDuration"] {
            query = query.filter(\.$dureActivity <= maxDuration)
        }

        // MARK: - Filtre date début (format unique dd-MM-yyyy)
        if let startString = req.query[String.self, at: "startDate"],
           let startDate = DateUtils.defaultFormatter.date(from: startString) {

            let startOfDay = utcCalendar.startOfDay(for: startDate)
            query = query.filter(\.$dateActivity >= startOfDay)
        }

        // MARK: - Filtre date fin (format unique dd-MM-yyyy)
        if let endString = req.query[String.self, at: "endDate"],
           let endDate = DateUtils.defaultFormatter.date(from: endString) {

            if let endOfDay = utcCalendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) {
                query = query.filter(\.$dateActivity <= endOfDay)
            }
        }

        // MARK: - Tri
        if let sort = req.query[String.self, at: "sort"] {
            switch sort.lowercased() {
            case "date":
                query = query.sort(\.$dateActivity, .descending)

            case "type":
                query = query.sort(\.$activityName, .ascending)

            case "duration":
                query = query.sort(\.$dureActivity, .descending)

            default: break
            }
        }

        let activities = try await query.all()
        return try activities.map { try ActivityResponse(from: $0) }
    }
    
    
    //MARK: Modification des données de l'activité de l'utilisateur
    @Sendable
    func updateActivity(req: Request) async throws -> ActivityResponse {
        let payload = try req.auth.require(UserPayload.self)

        guard let activityID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid activity ID format.")
        }

        // On récupère l’activité
        guard let activity = try await Activity.find(activityID, on: req.db) else {
            throw Abort(.notFound, reason: "Activity not found.")
        }

        // Vérifier que l'activité appartient à l'utilisateur
        guard activity.$user.id == payload.id else {
            throw Abort(.forbidden, reason: "You are not allowed to modify this activity.")
        }

        // Décodage du body JSON envoyé côté client
        let data = try req.content.decode(UpdateActivityDTO.self)

        // MARK: - Mise à jour des champs optionnels
        if let type = data.type {
            activity.activityName = type
        }

        if let duration = data.duration {
            guard duration > 0 else { throw Abort(.badRequest, reason: "La durée doit être supérieure à 0") }
            activity.dureActivity = duration
        }

        if let date = data.date {
            activity.dateActivity = date
        }

        // Calories : si elle sont fournies soit recalculées
        if let calories = data.caloriesBurned {
            guard calories >= 0 else {
                throw Abort(.badRequest, reason: "Les calories ne peuvent pas être négatives")
            }
            activity.caloriesBurned = calories
        } else {
            // Recalcul si le type ou la durée ont changé
            activity.caloriesBurned = ActivityDTO(
                type: activity.activityName,
                duration: activity.dureActivity,
                caloriesBurned: nil,
                date: activity.dateActivity
            ).estimatedCalories()
        }

        // Sauvegarder les modification de l'activité
        try await activity.update(on: req.db)
        return try ActivityResponse(from: activity)
    }

    
    //MARK: Suppression de l'activité de l'utilisateur
    @Sendable
    func deleteActivity(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)

        guard let activityID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Format d’ID d’activité invalide")
        }

        // Récupérer l'activité
        guard let activity = try await Activity.find(activityID, on: req.db) else {
            throw Abort(.notFound, reason: "l'activité n'existe pas")
        }

        // Vérifier l'autorisation de l'utilisateur
        guard activity.$user.id == payload.id else {
            throw Abort(.forbidden, reason: "Vous ne pouvez pas supprimer cette activité.")
        }

        // Supprime l'activité
        try await activity.delete(on: req.db)
        return .ok
    }
    
}
