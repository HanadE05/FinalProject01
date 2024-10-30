import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct Homepage: View {
    @State private var emails: [String] = []  // List of emails to display
    @State private var errorMessage: String?  // Display error if fetching fails
    @State private var isAddingUser: Bool = false // Track if "Add User" button is pressed

    private let db = Firestore.firestore()
    
    // Get the current logged-in user's UID
    private var currentUserID: String {
        Auth.auth().currentUser?.uid ?? "UnknownUser"
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Users You've Added")
                    .font(.largeTitle)
                    .padding(.top)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(emails, id: \.self) { email in
                        NavigationLink(destination: ChatView(otherUserEmail: email)) { // Updated parameter name to 'otherEmail'
                            Text(email)
                                .font(.body)
                        }
                    }
                }
                
                // Add User Button
                Button(action: {
                    isAddingUser = true
                }) {
                    Text("Add User")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                .padding(.top)
                .navigationTitle("Homepage")
                .navigationBarBackButtonHidden(true)
                
                // Navigate to AddNewUser when button is pressed
                .navigationDestination(isPresented: $isAddingUser) {
                    AddNewUser(onUserAdded: { newUser in
                        emails.append(newUser) // Update emails list when a new user is added
                    })
                }
            }
            .onAppear {
                fetchEmails()
            }
        }
    }
    
    private func fetchEmails() {
        db.collection("addedUsers")
            .whereField("addedBy", isEqualTo: currentUserID)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    errorMessage = "Failed to fetch emails: \(error.localizedDescription)"
                } else {
                    errorMessage = nil
                    emails = snapshot?.documents.compactMap { document in
                        document.data()["email"] as? String
                    } ?? []
                }
            }
    }
}

struct Homepage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Homepage()
        }
    }
}
