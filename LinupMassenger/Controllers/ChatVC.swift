//
//  ChatVC.swift
//  LinupMassenger
//
//  Created by BerkH on 23.02.2023.
//

import UIKit
import MessageKit
import InputBarAccessoryView


struct Message: MessageType {
    
    public var sender: MessageKit.SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKit.MessageKind
}

extension MessageKind {
    var messageKindString: String{
        switch self {
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: MessageKit.SenderType {
    
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}


class ChatVC: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, InputBarAccessoryViewDelegate {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public var otherUserEmail: String
    public var isNewConversation = false


    private var messages = [Message]()
    
    //let photoURL = URL(string: "https://iso.500px.com/wp-content/uploads/2016/03/stock-photo-142984111.jpg")
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        return Sender(photoURL: "",
                      senderId: email,
                      displayName: "Mark Thin")
        
    }
    
    /*private var selfSender: Sender

    init() {
        selfSender = Sender(photoURL: photoURL!, senderId: "1", displayName: "Mark Thin")
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }*/
    
    init(with email: String){
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self

        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageId = createMessageId() else {
            print("Error with send button")
                return
        }
        print("Sending: \(text)")
        
        //send message
        if isNewConversation{
            //create convo in database
            let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, firstMessage: message, complation: { success in
                if success {
                    print("message send")
                }else{
                    print("failed to send")
                }
            })

        }else{
            print("Message didn't send")
        }
    }
    
    private func createMessageId() -> String?{
        // date, otherUsersEmail, senderEmail, random
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_ \(dateString)"
        print("created message id: \(newIdentifier)")
        return newIdentifier
    }
    
    func currentSender() -> SenderType {
        if let sender = selfSender{
            return sender
        }
        fatalError("Self sender is nil, email should be cached")
        return Sender(photoURL: "", senderId: "12", displayName: "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }


}
