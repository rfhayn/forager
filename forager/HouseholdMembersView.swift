//
// HouseholdMembersView.swift
// forager
//
// M7.2.2 Task 4: Household members list display
// Shows all members with roles (Owner/Member) and statuses (Active/Pending)
//

import SwiftUI

struct HouseholdMembersView: View {
    let household: Household
    @ObservedObject var service: HouseholdService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(household.memberArray) { member in
                HouseholdMemberRow(member: member)
            }
        }
        .navigationTitle("Household Members")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct HouseholdMemberRow: View {
    let member: HouseholdMember
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(member.isOwner ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: member.isOwner ? "crown.fill" : "person.fill")
                    .foregroundStyle(member.isOwner ? .blue : .gray)
                    .font(.title3)
            }
            
            // Name and email
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.displayName ?? "Unknown")
                        .font(.headline)
                    
                    // Role badge
                    Text(member.isOwner ? "Owner" : "Member")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(member.isOwner ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                        .foregroundStyle(member.isOwner ? .blue : .gray)
                        .cornerRadius(4)
                }
                
                // Email
                Text(member.email ?? "No email")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Status indicator
            if member.isPending {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                    Text("Pending")
                        .font(.caption)
                }
                .foregroundStyle(.orange)
            } else if member.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct HouseholdMembersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HouseholdMembersView(
                household: previewHousehold(),
                service: HouseholdService(context: PersistenceController.preview.container.viewContext)
            )
        }
    }
    
    static func previewHousehold() -> Household {
        let context = PersistenceController.preview.container.viewContext
        let household = Household(context: context)
        household.id = UUID()
        household.name = "Preview Household"
        household.ownerEmail = "owner@example.com"
        
        // Owner member
        let owner = HouseholdMember(context: context)
        owner.id = UUID()
        owner.email = "owner@example.com"
        owner.displayName = "Sarah"
        owner.role = "owner"
        owner.status = "active"
        owner.joinedDate = Date()
        owner.household = household
        
        // Active member
        let member1 = HouseholdMember(context: context)
        member1.id = UUID()
        member1.email = "mike@example.com"
        member1.displayName = "Mike"
        member1.role = "member"
        member1.status = "active"
        member1.joinedDate = Date().addingTimeInterval(-86400)
        member1.household = household
        
        // Pending member
        let member2 = HouseholdMember(context: context)
        member2.id = UUID()
        member2.email = "alex@example.com"
        member2.displayName = "Alex"
        member2.role = "member"
        member2.status = "pending"
        member2.household = household
        
        return household
    }
}
