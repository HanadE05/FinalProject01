import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddNewUser: View {
    @State private var searchEmail = ""
    @State private var foundEmail: String? = nil
    @State private var errorMessage: String? = nil
    @Environment(\.presentationMode) var presentationMode  // Used to navigate back to Homepage
    
    private let db = Firestore.firestore()
    
    // Callback to add the user to the homepage list
    var onUserAdded: (String) -> Void
    
    // Current logged-in user's unique identifier
    var currentUserID: String {
        Auth.auth().currentUser?.uid ?? "UnknownUser"
    }
    
    // Current logged-in user's email
    var currentUserEmail: String {
        Auth.auth().currentUser?.email ?? ""
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Search for a User by Email")
                .font(.largeTitle)
                .padding(.top)
            
            TextField("Enter email", text: $searchEmail)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                searchForUser()
            }) {
                Text("Search")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.green)
                    .cornerRadius(8)
            }
            .padding(.bottom)
            
            if let foundEmail = foundEmail {
                Text("User found: \(foundEmail)")
                    .foregroundColor(.green)
                    .padding()
                
                Button(action: {
                    addUserToHomepage(foundEmail)
                }) {
                    Text("Add User to Homepage")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Add New User")
    }
    
    private func searchForUser() {
        // Clear previous results
        foundEmail = nil
        errorMessage = nil
        
        // Prevent user from adding themselves
        if searchEmail == currentUserEmail {
            errorMessage = "You cannot add yourself."
            return
        }
        
        // Search for the email in Firestore
        db.collection("users").whereField("email", isEqualTo: searchEmail).getDocuments { (snapshot, error) in
            if let error = error {
                errorMessage = "Error searching for user: \(error.localizedDescription)"
            } else if let snapshot = snapshot, !snapshot.isEmpty {
                // Email exists
                foundEmail = searchEmail
            } else {
                // Email does not exist
                errorMessage = "No user found with email \(searchEmail)"
            }
        }
    }
    
    private func addUserToHomepage(_ email: String) {
        // Check if the user is already in "addedUsers" for the current user
        db.collection("addedUsers")
            .whereField("email", isEqualTo: email)
            .whereField("addedBy", isEqualTo: currentUserID)
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Failed to check for existing user: \(error.localizedDescription)"
                } else if snapshot?.isEmpty == false {
                    // Email already exists in "addedUsers" for the current user
                    errorMessage = "User is already added to the homepage."
                } else {
                    // Add user to "addedUsers" if not already added
                    db.collection("addedUsers").addDocument(data: [
                        "email": email,
                        "addedBy": currentUserID
                    ]) { error in
                        if let error = error {
                            errorMessage = "Failed to add user: \(error.localizedDescription)"
                        } else {
                            onUserAdded(email) // Update homepage list in UI
                            presentationMode.wrappedValue.dismiss() // Dismiss AddNewUser view and go back to Homepage
                        }
                    }
                }
            }
    }
}
