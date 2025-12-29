//
// HouseholdDebugView.swift
// forager
//
// Debug view for household sync testing
//

import SwiftUI
import CoreData

struct HouseholdDebugView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Household.createdDate, ascending: false)],
        animation: .default)
    private var households: FetchedResults<Household>
    
    var body: some View {
        List {
            Section("Household Count") {
                Text("Total households in database: \(households.count)")
                    .font(.headline)
            }
            
            Section("All Households") {
                if households.isEmpty {
                    Text("No households found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(households) { household in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(household.name ?? "Unnamed")
                                .font(.headline)
                            Text("Owner: \(household.ownerEmail ?? "Unknown")")
                                .font(.caption)
                            Text("Members: \(household.members?.count ?? 0)")
                                .font(.caption)
                            if let created = household.createdDate {
                                Text("Created: \(created, style: .relative) ago")
                                    .font(.caption)
                            }
                            Text("ID: \(household.id?.uuidString ?? "nil")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Section("Actions") {
                Button("Refresh") {
                    viewContext.refreshAllObjects()
                }
                
                Button("Force Fetch") {
                    forceFetch()
                }
            }
        }
        .navigationTitle("Household Debug")
    }
    
    private func forceFetch() {
        let request: NSFetchRequest<Household> = Household.fetchRequest()
        do {
            let results = try viewContext.fetch(request)
            print("🔍 Force fetch found \(results.count) households:")
            for household in results {
                print("   - \(household.name ?? "Unnamed") (ID: \(household.id?.uuidString ?? "nil"))")
            }
        } catch {
            print("❌ Force fetch failed: \(error)")
        }
    }
}
