//
//  EditNoteView.swift
//  WeatherApp-Favorites
//
//  Created by Yerasyl Alimbek on 04.02.2026.
//

import SwiftUI
import Combine  // Add this import

struct EditNoteView: View {
    let favorite: FavoriteCity
    @Binding var note: String
    @Binding var isPresented: Bool
    
    @StateObject private var repository = FirebaseRepository.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Edit Note for \(favorite.name)")) {
                    TextEditor(text: $note)
                        .frame(height: 100)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Note")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    saveNote()
                }
                .disabled(isLoading)
            )
        }
    }
    
    private func saveNote() {
        Task {
            isLoading = true
            do {
                try await repository.updateFavorite(id: favorite.id, note: note.isEmpty ? nil : note)
                isPresented = false
            } catch {
                errorMessage = "Failed to update note: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}
