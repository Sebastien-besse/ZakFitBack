//
//  File.swift
//  ZakFitBack
//
//  Created by Sebastien Besse on 26/11/2025.
//

import Foundation
import Vapor
import JWTKit


//Déclaration de la structure utilisateur payload
struct UserPayload: JWTPayload, Authenticatable{
    
    var id: UUID
    var expiry: Date
    
    //Vérification de la validité du token
    func verify(using signer: JWTKit.JWTSigner) throws {
        if self.expiry < Date(){
            //Lance une erreur si le token est expiré
            throw JWTError.invalidJWK
        }
    }
    // Initialisateur qui définit l'ID et la date d'expiration
    init(id:UUID){
        self.id = id
        self.expiry = Date().addingTimeInterval(3600*24) // Expire dans 1 jour
    }
    
}


