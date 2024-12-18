//
//  CandidateListViewModel.swift
//  vitesse2
//
//  Created by TLiLi Hamdi on 13/12/2024.
//

import Foundation

@MainActor
class CandidateListViewModel: ObservableObject {
    @Published var candidates: [Candidate] = []
    @Published var errorMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var isLoading: Bool = false
    @Published var searchText = ""
    @Published var isEditing = false
    @Published var selectedCandidates: Set<String> = []
    @Published var showOnlyFavorites = false
    
    private let networkService = NetworkService.shared
    let isAdmin: Bool
    
    init(isAdmin: Bool) {
        self.isAdmin = isAdmin
        Task {
            await fetchCandidates()
        }
    }
    
    var filteredCandidates: [Candidate] {
        var filtered = candidates
        
        // Filtre de recherche
        if !searchText.isEmpty {
            filtered = filtered.filter { candidate in
                let searchTerms = searchText.lowercased().split(separator: " ")
                let candidateFullName = "\(candidate.firstName) \(candidate.lastName)".lowercased()
                
                return searchTerms.allSatisfy { term in
                    candidateFullName.contains(term) ||
                    candidate.email.lowercased().contains(term) ||
                    (candidate.phone?.lowercased().contains(term) ?? false)
                }
            }
        }
        
        // Filtre des favoris
        if showOnlyFavorites {
            filtered = filtered.filter { $0.isFavorite }
        }
        
        return filtered
    }
    
    func fetchCandidates() async {
        isLoading = true
        do {
            candidates = try await networkService.request(.candidates)
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    func deleteCandidate(_ candidate: Candidate) async {
        isLoading = true
        do {
            try await networkService.requestWithoutResponse(.deleteCandidate(id: candidate.id))
            await fetchCandidates()
        } catch {
            handleError(error)
        }
    }
    
    func toggleSelection(for candidate: Candidate) {
        if selectedCandidates.contains(candidate.id) {
            selectedCandidates.remove(candidate.id)
        } else {
            selectedCandidates.insert(candidate.id)
        }
    }
    
    func deleteSelectedCandidates() async {
        for candidateId in selectedCandidates {
            if let candidate = candidates.first(where: { $0.id == candidateId }) {
                await deleteCandidate(candidate)
            }
        }
        selectedCandidates.removeAll()
        isEditing = false
    }
    
    func deleteSelectedCandidatesSync() {
        Task {
            await deleteSelectedCandidates()
        }
    }
    
    func toggleFavorite(for candidate: Candidate) async {
        if !isAdmin {
            return  // Si non admin, on ignore simplement l'action
        }
        
        isLoading = true
        do {
            let updatedCandidate: Candidate = try await networkService.request(.toggleFavorite(id: candidate.id))
            if let index = candidates.firstIndex(where: { $0.id == candidate.id }) {
                candidates[index] = updatedCandidate
            }
            isLoading = false
        } catch {
            handleError(error)
        }
    }
    
    func toggleFavoriteSync(for candidate: Candidate) {
        Task {
            await toggleFavorite(for: candidate)
        }
    }
    
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
