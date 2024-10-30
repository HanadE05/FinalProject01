import SwiftUI
import FirebaseAuth

struct SignupView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var isSignedUp = false  // Navigation trigger for successful signup
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Sign Up")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    signUpUser()
                }) {
                    Text("Sign Up")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding()
                }
                
                Spacer()
                
                // Optionally, you can remove the link to LoginView
                NavigationLink(destination: LoginView()) {
                    Text("Already have an account? Log In")
                        .foregroundColor(.blue)
                        .padding(.top)
                }
                
                // Navigation to UserDetails after successful signup
                NavigationLink(destination: UserDetails(email: email), isActive: $isSignedUp) {
                    EmptyView()
                }
            }
            .padding()
            .navigationTitle("Sign Up")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func signUpUser() {
        // Ensure email and password are not empty
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password must not be empty."
            showAlert = true
            return
        }
        
        // Ensure password length is at least 6 characters
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            showAlert = true
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error as NSError? {
                // Check for specific error codes and provide more user-friendly messages
                if let errorCode = AuthErrorCode(rawValue: error.code) {  // Use AuthErrorCode directly
                    switch errorCode {
                    case .invalidEmail:
                        errorMessage = "The email address is badly formatted. Please use a valid email."
                    case .emailAlreadyInUse:
                        errorMessage = "An account with this email already exists. Try logging in."
                    case .weakPassword:
                        errorMessage = "The password is too weak. Please use at least 6 characters."
                    default:
                        errorMessage = error.localizedDescription
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
                showAlert = true
            } else {
                errorMessage = ""
                showAlert = false
                isSignedUp = true  // Trigger navigation to UserDetails on successful signup
            }
        }
    }
}
