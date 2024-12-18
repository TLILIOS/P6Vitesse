//
//  AddCandidateViewModel.swift
//  vitesse2
//
//  Created by TLiLi Hamdi on 14/12/2024.
//

import Foundation
@MainActor
class AddCandidateViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var linkedinURL: String = ""
    @Published var note: String = ""
    @Published var errorMessage: String = ""
    @Published var showAlert: Bool = false
    
    private let networkService = NetworkService.shared
    
    func saveCandidate() async -> Bool {
        guard isValidInput else {
            errorMessage = "Please fill in all required fields"
            showAlert = true
            return false
        }
        
        let candidate = CandidateRequest(
            email: email,
            note: note.isEmpty ? nil : note,
            linkedinURL: linkedinURL.isEmpty ? nil : linkedinURL,
            firstName: firstName,
            lastName: lastName,
            phone: phone.isEmpty ? nil : phone
        )
        
        do {
            let _: Candidate = try await networkService.request(.createCandidate(candidate))
            return true
        } catch {
            if let networkError = error as? NetworkService.NetworkError {
                errorMessage = networkError.message
            } else {
                errorMessage = "An unexpected error occurred"
            }
            showAlert = true
            return false
        }
    }
    
    private var isValidInput: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
