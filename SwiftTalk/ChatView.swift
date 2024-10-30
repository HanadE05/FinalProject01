import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatView: View {
    let otherUserEmail: String  // Email of the contact to chat with
    @State private var messageText: String = ""
    @State private var messages: [Message] = []
    @State private var errorMessage: String? = nil
    
    private let db = Firestore.firestore()
    
    // Get the current user's email to use as an identifier
    private var currentUserEmail: String {
        Auth.auth().currentUser?.email?.lowercased() ?? "UnknownUser"
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(messages) { message in
                        HStack {
                            if message.senderEmail == currentUserEmail {
                                Spacer()
                                Text(message.text)
                                    .padding()
                                    .background(Color.blue.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .padding(.horizontal, 10)
                            } else {
                                Text(message.text)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.black)
                                    .cornerRadius(10)
                                    .padding(.horizontal, 10)
                                Spacer()
                            }
                        }
                    }
                }
            }
            
            HStack {
                TextField("Enter message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 40)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Chat with \(otherUserEmail)")
        .onAppear(perform: loadMessages)
    }
    
    private func loadMessages() {
        // Set up a real-time listener for messages between the current user and the selected contact
        db.collection("messages")
            .whereField("participants", arrayContains: currentUserEmail)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    errorMessage = "Error loading messages: \(error.localizedDescription)"
                    print("Error loading messages: \(error.localizedDescription)")
                    return
                }
                
                messages = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    let senderEmail = data["senderEmail"] as? String ?? ""
                    let receiverEmail = data["receiverEmail"] as? String ?? ""
                    let text = data["text"] as? String ?? ""
                    
                    // Load messages where the current user is either the sender or receiver with the selected contact
                    if (senderEmail == currentUserEmail && receiverEmail == otherUserEmail) ||
                        (senderEmail == otherUserEmail && receiverEmail == currentUserEmail) {
                        print("Loaded message: \(text) from \(senderEmail) to \(receiverEmail)")
                        return Message(id: document.documentID, text: text, senderEmail: senderEmail, receiverEmail: receiverEmail)
                    }
                    return nil
                } ?? []
            }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let newMessage: [String: Any] = [
            "text": messageText,
            "senderEmail": currentUserEmail,
            "receiverEmail": otherUserEmail,
            "timestamp": Timestamp(),
            "participants": [currentUserEmail, otherUserEmail.lowercased()]
        ]
        
        db.collection("messages").addDocument(data: newMessage) { error in
            if let error = error {
                errorMessage = "Error sending message: \(error.localizedDescription)"
                print("Error sending message: \(error.localizedDescription)")
            } else {
                print("Message sent: \(messageText)")
                messageText = ""
            }
        }
    }
}

struct Message: Identifiable {
    var id: String
    var text: String
    var senderEmail: String
    var receiverEmail: String
}
