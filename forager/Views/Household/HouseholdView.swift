//
//  HouseholdView.swift
//  forager
//
//  M15.5b: Dedicated household management screen extracted from SettingsView
//  Provides household info, member management, sharing stats, and danger zone
//

import SwiftUI
import CoreData

struct HouseholdView: View {
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var syncMonitor: CloudKitSyncMonitor
    @Environment(\.managedObjectContext) private var viewContext

    // Async-loaded state
    @State private var isOwner = false
    @State private var participants: [ShareParticipant] = []
    @State private var ownerDisplayName = "Unknown"
    @State private var isLoadingParticipants = true

    // Editing state
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var renameError: String?

    // Sheet state
    @State private var showCreateSheet = false
    @State private var showInviteSheet = false

    // Danger zone state
    @State private var showLeaveConfirmation = false
    @State private var shouldMigrateData = false
    @State private var showDeleteConfirmation = false

    // Sharing stats
    @State private var sharedRecipeCount = 0
    @State private var sharedListCount = 0
    @State private var sharedPlanCount = 0
    @State private var sharedCategoryCount = 0
    @State private var sharedTemplateCount = 0

    var body: some View {
        List {
            if let household = householdService.currentHousehold {
                householdHeader(household)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                membersSection(household)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                inviteSection
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                sharingStatsSection
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                dangerZoneSection
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                noHouseholdSection
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(ForagerTheme.backgroundCanvas.ignoresSafeArea())
        .navigationTitle("Household")
        .navigationBarTitleDisplayMode(.large)
        // M10.6.16: Re-run when currentHousehold changes (e.g., after accepting invitation)
        .task(id: householdService.currentHousehold?.id) {
            isLoadingParticipants = true
            await loadHouseholdData()
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateHouseholdSheet(householdService: householdService)
        }
        .sheet(isPresented: $showInviteSheet) {
            if let household = householdService.currentHousehold {
                InviteMemberSheet(service: householdService, household: household)
            }
        }
        .alert("Leave Household?", isPresented: $showLeaveConfirmation) {
            Button("Migrate & Leave", role: .destructive) {
                shouldMigrateData = true
                if let household = householdService.currentHousehold {
                    leaveHousehold(household)
                }
            }
            Button("Clean App & Leave", role: .destructive) {
                shouldMigrateData = false
                if let household = householdService.currentHousehold {
                    leaveHousehold(household)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose 'Migrate & Leave' to keep a personal copy of all data, or 'Clean App & Leave' to start fresh.")
        }
        .alert("Delete Household?", isPresented: $showDeleteConfirmation) {
            Button("Migrate & Delete", role: .destructive) {
                if let household = householdService.currentHousehold {
                    deleteHousehold(household, migrateData: true)
                }
            }
            Button("Clean Delete", role: .destructive) {
                if let household = householdService.currentHousehold {
                    deleteHousehold(household, migrateData: false)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently deletes the household and removes all members' access. Choose 'Migrate & Delete' to keep a personal copy, or 'Clean Delete' to remove everything.")
        }
    }

    // MARK: - Household Header

    private func householdHeader(_ household: Household) -> some View {
        Section {
            VStack(spacing: ForagerTheme.Spacing.sm) {
                // Editable name row
                HStack {
                    if isEditingName {
                        TextField("Household Name", text: $editedName)
                            .font(ForagerTheme.cardTitle)
                            .onSubmit { saveHouseholdName(household) }
                    } else {
                        Text(household.name ?? "My Household")
                            .font(ForagerTheme.cardTitle)
                            .foregroundStyle(ForagerTheme.textPrimary)
                    }

                    Spacer()

                    if isOwner {
                        Button {
                            if isEditingName {
                                saveHouseholdName(household)
                            } else {
                                editedName = household.name ?? ""
                                isEditingName = true
                            }
                        } label: {
                            Image(systemName: isEditingName ? "checkmark" : "pencil")
                                .foregroundStyle(ForagerTheme.accentPrimary)
                        }
                    }
                }

                if let error = renameError {
                    Text(error)
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.statusDangerFG)
                }

                Divider()

                // M9.15.3: Live sync status from CloudKitSyncMonitor
                syncStatusRow
            }
            .padding(ForagerTheme.Spacing.lg)
            .background(ForagerTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                    .stroke(ForagerTheme.borderSubtle, lineWidth: 1)
            )
        }
    }

    // MARK: - Members Section

    private func membersSection(_ household: Household) -> some View {
        Section {
            VStack(spacing: ForagerTheme.Spacing.sm) {
                if isLoadingParticipants {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading members...")
                            .font(ForagerTheme.secondaryFont)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                } else {
                    ForEach(participants) { participant in
                        memberRow(participant)
                        if participant.id != participants.last?.id {
                            Divider()
                        }
                    }
                }

                Divider()

                ZStack {
                    NavigationLink {
                        HouseholdMembersView(household: household, service: householdService)
                    } label: { EmptyView() }
                        .opacity(0)
                    HStack {
                        Text("Manage Members")
                            .font(ForagerTheme.secondaryFont)
                            .foregroundStyle(ForagerTheme.accentPrimary)
                        Spacer()
                        Text("\(participants.count)")
                            .font(ForagerTheme.quantityFont)
                            .foregroundStyle(ForagerTheme.textTertiary)
                    }
                }
            }
            .padding(ForagerTheme.Spacing.lg)
            .background(ForagerTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                    .stroke(ForagerTheme.borderSubtle, lineWidth: 1)
            )
        } header: {
            Text("Members")
        }
    }

    private func memberRow(_ participant: ShareParticipant) -> some View {
        HStack(spacing: ForagerTheme.Spacing.md) {
            // Avatar: initials or icon
            ZStack {
                Circle()
                    .fill(participant.isOwner ? ForagerTheme.accentSecondary.opacity(0.2) : ForagerTheme.textTertiary.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: participant.isOwner ? "crown.fill" : "person.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(participant.isOwner ? ForagerTheme.accentSecondary : ForagerTheme.textTertiary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: ForagerTheme.Spacing.sm) {
                    Text(participant.displayName)
                        .font(ForagerTheme.bodyFont)
                        .foregroundStyle(ForagerTheme.textPrimary)

                    if participant.isCurrentUser {
                        Text("You")
                            .font(ForagerTheme.captionFont)
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                }

                // Role badge — printed tag (reskin-provisions-press)
                Text((participant.isOwner ? "Owner" : "Member").uppercased())
                    .font(.system(size: 10, weight: .bold).width(.condensed))
                    .tracking(0.5)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(participant.isOwner ? ForagerTheme.accentSecondary : ForagerTheme.textTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous))
            }

            Spacer()

            // Status indicator
            if participant.acceptanceStatus.isPending {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                    Text("Pending")
                        .font(ForagerTheme.captionFont)
                }
                .foregroundStyle(ForagerTheme.statusWarningFG)
            }
        }
    }

    // MARK: - Invite Section

    private var inviteSection: some View {
        Section {
            Button {
                showInviteSheet = true
            } label: {
                HStack {
                    Image(systemName: "paperplane")
                    Text("Invite Member")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ForagerTheme.Spacing.sm)
            }
            .buttonStyle(ForagerPrimaryButtonStyle())
        }
    }

    // MARK: - Sharing Stats

    private var sharingStatsSection: some View {
        Section {
            VStack(spacing: ForagerTheme.Spacing.sm) {
                HStack {
                    statItem("Recipes", count: sharedRecipeCount, icon: "book")
                    Spacer()
                    statItem("Lists", count: sharedListCount, icon: "cart")
                    Spacer()
                    statItem("Plans", count: sharedPlanCount, icon: "calendar")
                }
                HStack {
                    statItem("Categories", count: sharedCategoryCount, icon: "folder")
                    Spacer()
                    statItem("Ingredients", count: sharedTemplateCount, icon: "text.badge.checkmark")
                    Spacer()
                    // Empty spacer to balance the 3-column grid
                    Color.clear.frame(maxWidth: .infinity)
                }
            }
            .padding(ForagerTheme.Spacing.lg)
            .background(ForagerTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                    .stroke(ForagerTheme.borderSubtle, lineWidth: 1)
            )
        } header: {
            Text("Shared Data")
        }
    }

    private func statItem(_ label: String, count: Int, icon: String) -> some View {
        VStack(spacing: ForagerTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(ForagerTheme.accentSecondary)
            Text("\(count)")
                .font(.system(size: 22, weight: .semibold, design: .monospaced))
                .foregroundStyle(ForagerTheme.textPrimary)
            Text(label)
                .font(ForagerTheme.captionFont)
                .foregroundStyle(ForagerTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        Section {
            VStack {
                if isOwner {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Label("Delete Household", systemImage: "trash")
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderless)
                } else {
                    Button(role: .destructive) {
                        showLeaveConfirmation = true
                    } label: {
                        HStack {
                            Label("Leave Household", systemImage: "rectangle.portrait.and.arrow.right")
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(ForagerTheme.Spacing.lg)
            .background(ForagerTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                    .stroke(ForagerTheme.borderSubtle, lineWidth: 1)
            )
        } header: {
            Text("Danger Zone")
        } footer: {
            Text(isOwner
                ? "Deleting removes all shared data for all members."
                : "Leaving removes your access to shared recipes, lists, and meal plans.")
                .font(ForagerTheme.captionFont)
        }
    }

    // MARK: - No Household State

    private var noHouseholdSection: some View {
        Section {
            VStack(spacing: ForagerTheme.Spacing.lg) {
                Image(systemName: "person.3")
                    .font(.system(size: 40))
                    .foregroundStyle(ForagerTheme.accentSecondary)
                Text("Share recipes, lists, and meal plans with family")
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                    .multilineTextAlignment(.center)

                // M9.15.3: Show discovery status when checking for existing household
                if householdService.discoveryState == .checking {
                    discoveryStatusRow
                }

                Button("Create Household") {
                    showCreateSheet = true
                }
                .buttonStyle(ForagerPrimaryButtonStyle())
            }
            .frame(maxWidth: .infinity)
            .padding(ForagerTheme.Spacing.lg)
            .background(ForagerTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous)
                    .stroke(ForagerTheme.borderSubtle, lineWidth: 1)
            )
        } footer: {
            if householdService.discoveryState == .checking {
                Text("If you were previously in a household, your data is syncing from iCloud. You can create a new household at any time.")
                    .font(ForagerTheme.captionFont)
            } else {
                Text("All household members will automatically share grocery lists, recipes, and meal plans via iCloud.")
                    .font(ForagerTheme.captionFont)
            }
        }
    }

    // MARK: - M9.15.3: Sync Status Views

    /// Live sync status for household header (replaces hardcoded green dot)
    private var syncStatusRow: some View {
        HStack(spacing: ForagerTheme.Spacing.sm) {
            switch syncMonitor.syncState {
            case .syncing:
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 8, height: 8)
                Text("Syncing...")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
            case .synced:
                Circle()
                    .fill(ForagerTheme.statusSuccessFG)
                    .frame(width: 8, height: 8)
                if let lastSync = syncMonitor.lastSyncDate {
                    Text("Synced \(lastSync, style: .relative) ago")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                } else {
                    Text("iCloud synced")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                }
            case .error(let message):
                Circle()
                    .fill(ForagerTheme.statusWarningFG)
                    .frame(width: 8, height: 8)
                Text(message)
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.statusWarningFG)
                    .lineLimit(1)
            case .idle:
                Circle()
                    .fill(ForagerTheme.textTertiary)
                    .frame(width: 8, height: 8)
                Text("iCloud idle")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
            }
        }
    }

    /// Discovery progress indicator for the no-household state
    private var discoveryStatusRow: some View {
        HStack(spacing: ForagerTheme.Spacing.sm) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Checking iCloud for existing household...")
                .font(ForagerTheme.captionFont)
                .foregroundStyle(ForagerTheme.textSecondary)
        }
        .padding(.vertical, ForagerTheme.Spacing.xs)
    }

    // MARK: - Data Loading

    private func loadHouseholdData() async {
        guard let household = householdService.currentHousehold else { return }

        isOwner = await householdService.isOwner(household: household)

        if let owner = await householdService.getOwnerParticipant(for: household) {
            ownerDisplayName = owner.displayName
        }

        do {
            participants = try await householdService.getParticipants(for: household)
        } catch {
            #if DEBUG
            print("HouseholdView: Failed to load participants: \(error)")
            #endif
        }
        isLoadingParticipants = false

        loadSharingStats(household)
    }

    private func loadSharingStats(_ household: Household) {
        guard let householdKey = household.id?.uuidString else { return }

        let recipeRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        recipeRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)

        let listRequest: NSFetchRequest<WeeklyList> = WeeklyList.fetchRequest()
        listRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)

        let planRequest: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
        planRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)

        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)

        let templateRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        templateRequest.predicate = NSPredicate(format: "householdKey == %@", householdKey)

        do {
            sharedRecipeCount = try viewContext.count(for: recipeRequest)
            sharedListCount = try viewContext.count(for: listRequest)
            sharedPlanCount = try viewContext.count(for: planRequest)
            sharedCategoryCount = try viewContext.count(for: categoryRequest)
            sharedTemplateCount = try viewContext.count(for: templateRequest)
        } catch {
            #if DEBUG
            print("HouseholdView: Failed to load sharing stats: \(error)")
            #endif
        }
    }

    // MARK: - Actions

    private func saveHouseholdName(_ household: Household) {
        Task {
            do {
                try await householdService.renameHousehold(household, to: editedName)
                isEditingName = false
                renameError = nil
                await householdService.loadCurrentHousehold()
            } catch {
                renameError = error.localizedDescription
            }
        }
    }

    private func leaveHousehold(_ household: Household) {
        Task {
            do {
                try await householdService.leaveHousehold(household, migrateData: shouldMigrateData)
                await householdService.loadCurrentHousehold()
            } catch {
                #if DEBUG
                print("Error leaving household: \(error)")
                #endif
            }
        }
    }

    private func deleteHousehold(_ household: Household, migrateData: Bool) {
        Task {
            do {
                try await householdService.deleteHousehold(household, migrateData: migrateData)
                await householdService.loadCurrentHousehold()
            } catch {
                #if DEBUG
                print("Error deleting household: \(error)")
                #endif
            }
        }
    }
}

// MARK: - Preview

struct HouseholdView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HouseholdView()
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(HouseholdService(context: PersistenceController.preview.container.viewContext))
        .environmentObject(CloudKitSyncMonitor())
    }
}
