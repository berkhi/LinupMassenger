//
//  ChatVC.swift
//  LinupMassenger
//
//  Created by BerkH on 23.02.2023.
//

import UIKit
import MessageKit

struct Message: MessageType {
    
    var sender: MessageKit.SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKit.MessageKind
}

struct Sender: MessageKit.SenderType {
    
    var photoURL: URL
    var senderId: String
    var displayName: String
}


class ChatVC: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {

    private var messages = [Message]()
    
    let photoURL = URL(string: "https://iso.500px.com/wp-content/uploads/2016/03/stock-photo-142984111.jpg")
    /*private let selfSender = Sender(photoURL: photourl!,
                                    senderId: "1",
                                    displayName: "Mark Thin")*/
    
    private var selfSender: Sender

    init() {
        selfSender = Sender(photoURL: photoURL!, senderId: "1", displayName: "Mark Thin")
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messages.append(Message(sender: selfSender,
                                messageId: "1",
                                sentDate: Date(),
                                kind: .text("LoremImpsum")))
        
        messages.append(Message(sender: selfSender, messageId: "1",
                                sentDate: Date(),
                                kind: .text("LoremImpsum LoremImpsum LoremImpsum LoremImpsum LoremImpsum LoremImpsum LoremImpsumLoremImpsumLoremImpsum")))
        
        view.backgroundColor = .red
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self

        // Do any additional setup after loading the view.
    }
    func currentSender() -> MessageKit.SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }


}
