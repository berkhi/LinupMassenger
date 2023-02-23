//
//  DatabaseManager.swift
//  LinupMassenger
//
//  Created by BerkH on 14.02.2023.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    private let database = Database.database().reference()


}

extension DatabaseManager{
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)){
        
        var guardEmail = email.replacingOccurrences(of: ".", with: "-")
        guardEmail = guardEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(guardEmail).observeSingleEvent(of: .value, with: {snapshot in
            guard snapshot.value as? String != nil else{
                completion(false)
                return
            }
            completion(true)
        })
        
    }
    ///Inserts new user to database
    public func insertUser(with user: AppUserInfo){
        database.child(user.guardEmail).setValue(["first_name": user.firstName, "last_name": user.lastName])
    }
    
}

struct AppUserInfo{
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var guardEmail: String{
        var guardEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        guardEmail = guardEmail.replacingOccurrences(of: "@", with: "-")
        return guardEmail
    }
    
}
