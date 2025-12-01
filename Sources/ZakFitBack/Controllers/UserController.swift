//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 25/11/2025.
//

import Vapor
import Fluent
import JWT

struct UserController: RouteCollection{
    
    // Définition des routes
    func boot(routes: any RoutesBuilder) throws {
        // Je regroupe mes routes
        let user = routes.grouped("users")
        user.post("create", use: createUser)
        user.post("login", use: login)
        
        // Groupe de routes nécessitant le middleware JWT
        let protectedRoutes = user.grouped(JWTMiddleware())
        // Accès aux informations de profil
        protectedRoutes.get("users", use: getAll)
        protectedRoutes.get("profil", use: getUserById)
        protectedRoutes.put("update", use: updateUser)
        protectedRoutes.delete("delete", use: deleteUser)
    }
    
    //MARK: Créer un utilisateur
    @Sendable
    func createUser(req: Request) async throws -> UserResponse{
        // je decode le contenu json envoyé par le client
        let userDTO = try req.content.decode(UserDTO.self).toModel()
        
        // Validation de l'email si il est pas déjà utiliser
        if let _ = try await User.query(on: req.db)
            .filter(\.$email == userDTO.email)
            .first() {
            throw Abort(.badRequest, reason: "Email déjà utilisé.")
        }
        
        // Validation du mot de passe si il contient suffisament de caractères
        guard userDTO.password.count >= 8 else {
            throw Abort(.badRequest, reason: "Le mot de passe doit contenir au moins 8 caractères.")
        }
        
        // Permet de hasher le mot de passe
        userDTO.password = try Bcrypt.hash(userDTO.password)
        
        // J'envoie en base de données les données de l'utilisateur
        try await userDTO.create(on: req.db)
        
        // Je retourne un model contenant les données utilisateur
        return UserResponse(firstname: userDTO.firstname, lastname: userDTO.lastname, email: userDTO.email, dateOfBirth: userDTO.dateOfBirth,gender: userDTO.gender, height: userDTO.height, weight: userDTO.weight, objectifHealth: userDTO.objectifHealth, diet: userDTO.diet)
        
    }
    
    // MARK: Connexion d'un utilisateur
    @Sendable
    func login(req: Request) async throws -> String {
        // Décoder les données utilisateur à partir de la requête
        let userData = try req.content.decode(UserDTOAuth.self)
        
        // Rechercher l'utilisateur par email
        let email = userData.email
        
        // Véfirication de l'email si il est bien identique a celui en base de donnée
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == email)
            .first() else {
            throw Abort(.unauthorized, reason: "Email incorrect.")
        }
        
        // Vérification du mot de passe
        guard try Bcrypt.verify(userData.password, created: user.password) else {
            throw Abort(.unauthorized, reason: "Mot de passe incorrect.")
        }
        
        // Génération du token JWT
        let payload = UserPayload(id: user.id!)
        let signer = JWTSigner.hs256(key: "clé_secrète_Zakfit")
        let token = try signer.sign(payload)
        
        return token
    }
    //MARK: Récupération de tout les utilisateurs
    @Sendable
    func getAll(req: Request) async throws -> [UserResponse]{
        let payload = try req.auth.require(UserPayload.self)
        guard (try await User.find(payload.id, on: req.db)) != nil else {
            throw Abort (.notFound)
        }
        let users = try await User.query(on: req.db).all()
        return try users.map { try UserResponse(from: $0) }
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
    
    //MARK: Modification des données utilisateur
    @Sendable
    func updateUser(_ req: Request) async throws -> UserResponse {
        // Récupérer le payload JWT
        let payload = try req.auth.require(UserPayload.self)
        
        // Récupérer l'utilisateur depuis la base
        guard let user = try await User.find(payload.id, on: req.db) else {
            throw Abort(.notFound, reason: "Utilisateur introuvable.")
        }
        
        // Décoder les nouvelles données envoyées par le client
        let updateData = try req.content.decode(UserDTO.self)
        
        // Validation de l'email si il est pas déjà utiliser
        if updateData.email != user.email {
            if let _ = try await User.query(on: req.db)
                .filter(\.$email == updateData.email)
                .first() {
                throw Abort(.badRequest, reason: "Email déjà utilisé.")
            }
        }
        
        // Validation mot de passe si il y a un changement
        if !updateData.password.isEmpty {
            guard updateData.password.count >= 8 else {
                throw Abort(.badRequest, reason: "Le mot de passe doit contenir au moins 8 caractères.")
            }
            user.password = try Bcrypt.hash(updateData.password)
        }
        
        // mise à jour des champs
        user.firstname = updateData.firstname
        user.lastname = updateData.lastname
        user.email = updateData.email
        user.height = updateData.height
        user.weight = updateData.weight
        user.objectifHealth = updateData.objectifHealth
        user.diet = updateData.diet
        
        // Si un mot de passe est envoyé → on le rehash
        if !updateData.password.isEmpty {
            user.password = try Bcrypt.hash(updateData.password)
        }
        
        // Enregistre les changements
        try await user.save(on: req.db)
        
        // Retourne la version mis à jour du user
        return try UserResponse(from: user)
    }
    
    //MARK: Suppression de l'utilisateur
    @Sendable
    func deleteUser(_ req: Request) async throws -> HTTPStatus {
        //Vérifie que le token JWT est valide
        let payload = try req.auth.require(UserPayload.self)
        
        //Récupère l’utilisateur à supprimer
        guard let user = try await User.find(payload.id, on: req.db) else {
            throw Abort(.notFound, reason: "Utilisateur introuvable.")
        }
        
        //Supprime l’utilisateur
        try await user.delete(on: req.db)
        
        return .ok
    }
    
    
}
