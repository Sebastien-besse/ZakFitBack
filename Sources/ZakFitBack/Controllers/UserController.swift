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
        protectedRoutes.delete("delete", use: deleteUser)
        protectedRoutes.get("profil", use: getUserById)
        
        
    }
    
    //MARK: Créer un utilisateur
    @Sendable
    func createUser(req: Request) async throws -> UserResponse{
        // je decode le contenu json envoyé par le client
        let userDTO = try req.content.decode(UserDTO.self).toModel()
        
        // Permet de hasher le mot de passe
        userDTO.password = try Bcrypt.hash(userDTO.password)

        // J'envoie en base de données les données de l'utilisateur
        try await userDTO.create(on: req.db)
        
        // Je retourne un model contenant les données utilisateur
        return UserResponse(firstname: userDTO.firstname, lastname: userDTO.lastname, email: userDTO.email, dateOfBirth: userDTO.dateOfBirth, height: userDTO.height, weight: userDTO.weight, objectifHealth: userDTO.objectifHealth, diet: userDTO.diet)
        
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
        
        return .noContent
    }
    
    
}
