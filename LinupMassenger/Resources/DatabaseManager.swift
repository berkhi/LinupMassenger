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

///Sending messages / conversations

extension DatabaseManager {
    
    /// Creates new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, complation: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard var userNode = snapshot.value as? [String: Any] else{
                complation(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatVC.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            let conversationID = "conversations_\(firstMessage.messageId)"
            let newConversationData: [String: Any] = [
                "id": conversationID,
                "otherUserEmail": otherUserEmail,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]]{
                // conversation array exists for current user
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: {[weak self] error, _ in
                    guard error == nil else{
                        complation(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationID: conversationID, firstMessage: firstMessage, completion: complation)
                })
                
            }else{
                userNode["conversations"] = [
                    newConversationData
                ]
                ref.setValue(userNode, withCompletionBlock: {[weak self] error, _ in
                    guard error == nil else{
                        complation(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationID: conversationID, firstMessage: firstMessage, completion: complation)
                })
                
                
            }
        })
    }
    public func finishCreatingConversation(conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        let messageDate = firstMessage.sentDate
        let dateString = ChatVC.dateFormatter.string(from: messageDate)
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        database.child("\(conversationID)").setValue(value, withCompletionBlock: {error, _ in
            guard error == nil else{
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Fetches and returns all conversations for user with past in email
    public func getAllConversation(for email: String, comletion: @escaping (Result<String, Error>) -> Void){
        
    }
    
    /// get all messages for a given conversation 
    public func getAllMessagesForConversation(with id: String, complation: @escaping (Result<String, Error>) -> Void){
        
    }
    ///Sends a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, comletion: @escaping (Bool) -> Void){
        
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
