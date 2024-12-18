import Foundation
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    // MARK: - Published properties
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var isAdmin: Bool = false
    @Published var isLoading: Bool = false
    
    // MARK: - Dependencies
    private let networkService = NetworkService.shared
    
    // MARK: - Validation
    private var isValidInput: Bool {
        !email.isEmpty && !password.isEmpty && isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Authentication methods
    func login() async {
        guard isValidInput else {
            handleError(NetworkError.invalidInput)
            return
        }
        
        isLoading = true
        do {
            let response: AuthResponse = try await networkService.request(.login(email: email, password: password))
            print("Login successful, token received")
            await networkService.setToken(response.token)
            
            if let storedToken = TokenManager.shared.getToken() {
                print("Token successfully stored: \(String(storedToken.prefix(10)))...")
                isAuthenticated = true
                isAdmin = response.isAdmin
            } else {
                print("Failed to store token")
                throw NetworkError.unauthorized
            }
        } catch {
            print("Login error: \(error)")
            handleError(error)
            isAuthenticated = false
            isAdmin = false
        }
        isLoading = false
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkService.NetworkError {
            errorMessage = networkError.message
        } else {
            errorMessage = "Une erreur inattendue s'est produite"
        }
        showAlert = true
        isLoading = false
    }
}

// MARK: - Custom Error
extension LoginViewModel {
    enum NetworkError: Error {
        case invalidInput
        case unauthorized
        
        var message: String {
            switch self {
            case .invalidInput:
                return "Veuillez entrer un email et un mot de passe valides."
            case .unauthorized:
                return "Authentification échouée. Veuillez réessayer."
            }
        }
    }
}
