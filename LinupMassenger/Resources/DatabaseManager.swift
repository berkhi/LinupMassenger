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
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
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
    public func insertUser(with user: AppUserInfo, completion: @escaping(Bool) -> Void ){
        database.child(user.guardEmail).setValue(["first_name": user.firstName,
                                                  "last_name": user.lastName
                                                 ], withCompletionBlock: {error, _ in
            guard error == nil else{
                print("Faild to write databese")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value, with: {snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    //Append to users dictionary
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.guardEmail
                    ]
                    usersCollection.append(newElement)
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                    
                }else {
                    //create that array
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.guardEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                        
                    })
                }
            })
            
            completion(true)
        })
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: {snapshot in
            guard let value = snapshot.value as? [[String: String]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    public enum DatabaseError : Error{
        case failedToFetch
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
    
    var profilePictureFileName: String {
        //berk-gmail-com_profile_picture.png
        return "\(guardEmail)_profile_picture.png"
    }
}
