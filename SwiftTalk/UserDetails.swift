import SwiftUI
import FirebaseFirestore

struct UserDetails: View {
    var email: String
    @State private var firstName = ""
    @State private var surname = ""
    @State private var username = ""
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var navigateToHomepage = false  // Navigation trigger for Homepage
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Your Details")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("First Name", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Surname", text: $surname)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                saveUserDetails()
            }) {
                Text("Next")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.green)
                    .cornerRadius(8)
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding()
            }
            
            Spacer()
            
            // Navigation to Homepage after successful details save
            NavigationLink(destination: Homepage(), isActive: $navigateToHomepage) {
                EmptyView()
            }
        }
        .padding()
        .navigationTitle("User Details")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func saveUserDetails() {
        // Check if username is unique
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { (snapshot, error) in
            if let error = error {
                errorMessage = "Failed to check username: \(error.localizedDescription)"
                showAlert = true
            } else if let snapshot = snapshot, !snapshot.isEmpty {
                // Username already exists
                errorMessage = "Username is already taken. Please choose another."
                showAlert = true
            } else {
                // Save user details in Firestore
                let userData: [String: Any] = [
                    "email": email,
                    "firstName": firstName,
                    "surname": surname,
                    "username": username
                ]
                
                db.collection("users").addDocument(data: userData) { error in
                    if let error = error {
                        errorMessage = "Failed to save user details: \(error.localizedDescription)"
                        showAlert = true
                    } else {
                        // Successfully saved, navigate to Homepage
                        errorMessage = ""
                        showAlert = false
                        navigateToHomepage = true
                    }
                }
            }
        }
    }
}
