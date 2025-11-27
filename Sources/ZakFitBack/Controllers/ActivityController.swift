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
    @Sendable
    func getActivities(req: Request) async throws -> [ActivityResponse] {
        let payload = try req.auth.require(UserPayload.self)
        
        // Préparer le calendrier UTC une seule fois
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        // Début de la requête filtrée par userID
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

        // MARK: - Filtres par dates
        if let start = req.query[QueryDate.self, at: "startDate"] {
            let startOfDay = utcCalendar.startOfDay(for: start.date)
            query = query.filter(\.$dateActivity >= startOfDay)
        }

        if let end = req.query[QueryDate.self, at: "endDate"] {
            // Fin de journée UTC
            if let endOfDay = utcCalendar.date(bySettingHour: 23, minute: 59, second: 59, of: end.date) {
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
            default:
                break
            }
        }

        // MARK: - Exécution
        let activities = try await query.all()
        return try activities.map { try ActivityResponse(from: $0) }
    }

    
    
    //MARK: Récupére un utilisateur par son ID depuis le payload
    @Sendable
    func getUserById(req: Request) async throws -> UserResponse {
        // Essaye d'extraire le payload JWT de la requête
        let payload = try req.auth.require(UserPayload.self)
        // Recherche l'utilisateur dans la base de données en utilisant l'ID extrait du payload
        guard let user = try await User.find(payload.id, on: req.db) else {
            throw Abort (.notFound)
        }
        // Convertit l'utilisateur en DTO pour ne retourner que les informations nécessaires
        return try UserResponse(from: user)
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

        // Décodage du body JSON
        let data = try req.content.decode(UpdateActivityDTO.self)

        // MARK: - Mise à jour des champs optionnels
        if let type = data.type {
            activity.activityName = type
        }

        if let duration = data.duration {
            guard duration > 0 else { throw Abort(.badRequest, reason: "Duration must be greater than 0.") }
            activity.dureActivity = duration
        }

        if let date = data.date {
            activity.dateActivity = date
        }

        // Calories : soit fournies soit recalculées
        if let calories = data.caloriesBurned {
            guard calories >= 0 else { throw Abort(.badRequest, reason: "Calories cannot be negative.") }
            activity.caloriesBurned = calories
        } else {
            // Recalcul si type ou durée ont changé
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
            throw Abort(.badRequest, reason: "Invalid activity ID format.")
        }

        // Récupérer l'activité
        guard let activity = try await Activity.find(activityID, on: req.db) else {
            throw Abort(.notFound, reason: "l'activité n'existe pas.")
        }

        // Vérifier l'autorisation de l'utilisateur
        guard activity.$user.id == payload.id else {
            throw Abort(.forbidden, reason: "You cannot delete this activity.")
        }

        // Supprimer
        try await activity.delete(on: req.db)
        return .ok
    }
    
}
