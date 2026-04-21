//
//  QuantityMergeService.swift
//  forager
//
//  M3 Phase 5: Intelligent Shopping List Consolidation with Unit Conversion
//  Combines duplicate ingredients with compatible quantities
//

import Foundation
import CoreData
import Combine

class QuantityMergeService: ObservableObject {
    
    private let context: NSManagedObjectContext
    private let conversionService = UnitConversionService()
    
    // Performance tracking
    @Published var lastAnalysisTime: TimeInterval = 0.0
    @Published var lastMergeTime: TimeInterval = 0.0
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Main Analysis Function
    
    /// Analyze grocery list items for consolidation opportunities
    func analyzeMergeOpportunities(for list: WeeklyList) -> MergeAnalysis {
        let startTime = Date()
        
        guard let itemsSet = list.items else {
            lastAnalysisTime = Date().timeIntervalSince(startTime)
            return MergeAnalysis(list: list, groups: [], totalSavings: 0)
        }
        
        // Only analyze incomplete items
        let items = (Array(itemsSet) as! [GroceryListItem]).filter { !$0.isCompleted }
        
        // Group by ingredient name (case-insensitive)
        let grouped = Dictionary(grouping: items) { item -> String in
            return item.name?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
        }
        
        var mergeGroups: [MergeGroup] = []
        var potentialSavings = 0
        
        for (ingredientName, groupItems) in grouped where groupItems.count > 1 && !ingredientName.isEmpty {
            // NEW: Group by unit CATEGORY instead of exact unit match
            let compatibleSets = groupCompatibleQuantitiesWithConversion(groupItems)
            
            if let mergedGroup = createMergeGroup(
                ingredientName: ingredientName,
                items: groupItems,
                compatibleSets: compatibleSets
            ) {
                mergeGroups.append(mergedGroup)
                potentialSavings += (groupItems.count - mergedGroup.resultCount)
            }
        }
        
        lastAnalysisTime = Date().timeIntervalSince(startTime)
        
        return MergeAnalysis(
            list: list,
            groups: mergeGroups.sorted { $0.savingsCount > $1.savingsCount },
            totalSavings: potentialSavings
        )
    }
    
    // MARK: - Enhanced Compatibility Analysis with Unit Conversion
    
    private func groupCompatibleQuantitiesWithConversion(_ items: [GroceryListItem]) -> [[GroceryListItem]] {
        var compatibleSets: [[GroceryListItem]] = []
        
        // Separate parseable from unparseable
        let parseable = items.filter { $0.isParseable && $0.standardUnit != nil }
        let unparseable = items.filter { !$0.isParseable || $0.standardUnit == nil }
        
        // NEW: Group parseable by unit CATEGORY (volume, weight, count)
        let byCategory = Dictionary(grouping: parseable) { item -> String in
            guard let unit = item.standardUnit else { return "none" }
            let category = conversionService.getUnitCategory(unit)
            return "\(category)"
        }
        
        // Each category becomes a mergeable set (with unit conversion)
        for (category, categoryItems) in byCategory where category != "unknown" && category != "count" {
            if categoryItems.count > 1 {
                compatibleSets.append(categoryItems)
            } else {
                // Single item in category
                compatibleSets.append(categoryItems)
            }
        }
        
        // Count units and unknown must match exactly (no conversion)
        let countAndUnknown = parseable.filter {
            guard let unit = $0.standardUnit else { return false }
            let category = conversionService.getUnitCategory(unit)
            return category == .count || category == .unknown
        }
        
        // Group count units by exact unit match only
        let byExactUnit = Dictionary(grouping: countAndUnknown) { $0.standardUnit ?? "" }
        for (_, unitItems) in byExactUnit where unitItems.count > 1 {
            compatibleSets.append(unitItems)
        }
        
        // Each unparseable is its own group (can't merge)
        for item in unparseable {
            compatibleSets.append([item])
        }
        
        return compatibleSets
    }
    
    private func createMergeGroup(
        ingredientName: String,
        items: [GroceryListItem],
        compatibleSets: [[GroceryListItem]]
    ) -> MergeGroup? {
        
        var mergedItems: [MergedItem] = []
        
        for itemSet in compatibleSets {
            if itemSet.count > 1 && canMergeWithConversion(itemSet) {
                // NEW: Mergeable set - combine quantities with unit conversion
                let (totalValue, bestUnit) = combineQuantitiesWithConversion(itemSet)
                let sources = itemSet.compactMap { $0.source }.filter { !$0.isEmpty }
                
                mergedItems.append(MergedItem(
                    displayText: formatMergedQuantity(value: totalValue, unit: bestUnit),
                    sourceCount: itemSet.count,
                    sources: sources,
                    originalItems: itemSet,
                    isMerged: true,
                    isConverted: hasMultipleUnits(itemSet)  // Flag if conversion happened
                ))
            } else {
                // Keep separate
                for item in itemSet {
                    let source = item.source ?? "unknown"
                    mergedItems.append(MergedItem(
                        displayText: item.displayText ?? item.name ?? "",
                        sourceCount: 1,
                        sources: [source],
                        originalItems: [item],
                        isMerged: false,
                        isConverted: false
                    ))
                }
            }
        }
        
        // Only create group if there's actual consolidation
        guard mergedItems.count < items.count else { return nil }
        
        return MergeGroup(
            ingredientName: ingredientName.capitalized,
            originalCount: items.count,
            mergedItems: mergedItems,
            savingsCount: items.count - mergedItems.count
        )
    }
    
    // NEW: Check if items have different units (conversion needed)
    private func hasMultipleUnits(_ items: [GroceryListItem]) -> Bool {
        let units = Set(items.compactMap { $0.standardUnit?.lowercased() })
        return units.count > 1
    }
    
    // NEW: Enhanced merge check with unit conversion support
    private func canMergeWithConversion(_ items: [GroceryListItem]) -> Bool {
        // All must be parseable
        guard items.allSatisfy({ $0.isParseable && $0.standardUnit != nil }) else {
            return false
        }
        
        // Get all units
        let units = items.compactMap { $0.standardUnit }
        guard !units.isEmpty else { return false }
        
        // Check if all units are compatible (same category)
        let firstUnit = units[0]
        return units.allSatisfy { unit in
            conversionService.areUnitsCompatible(firstUnit, unit)
        }
    }
    
    // NEW: Combine quantities with automatic unit conversion
    private func combineQuantitiesWithConversion(_ items: [GroceryListItem]) -> (value: Double, unit: String) {
        guard !items.isEmpty else { return (0.0, "") }
        
        // Collect all quantities with their units
        let quantities = items.compactMap { item -> (value: Double, unit: String)? in
            guard let unit = item.standardUnit, item.numericValue > 0 else { return nil }
            return (item.numericValue, unit)
        }
        
        guard !quantities.isEmpty else { return (0.0, items[0].standardUnit ?? "") }
        
        // Select best target unit
        let targetUnit = conversionService.selectBestUnit(quantities: quantities) ?? quantities[0].unit
        
        // Convert all to target unit and sum
        var total = 0.0
        for (value, unit) in quantities {
            if let converted = conversionService.convert(value: value, from: unit, to: targetUnit) {
                total += converted
            } else {
                // Fallback: if conversion fails, just add the value
                total += value
            }
        }
        
        return (total, targetUnit)
    }
    
    // MARK: - Merge Execution
    
    func executeMerge(analysis: MergeAnalysis) throws {
        let startTime = Date()
        
        guard let list = analysis.list else {
            throw MergeError.invalidList
        }
        
        for group in analysis.groups {
            for mergedItem in group.mergedItems where mergedItem.isMerged {
                // Create single consolidated item
                let consolidated = GroceryListItem(context: context)
                // Co-locate with parent list to prevent CloudKit zone conflict (134040).
                if let parentStore = list.objectID.persistentStore {
                    context.assign(consolidated, to: parentStore)
                }
                consolidated.id = UUID()
                consolidated.name = group.ingredientName
                consolidated.displayText = mergedItem.displayText
                
                // NEW: If conversion happened, recalculate the combined quantity
                let (combinedValue, combinedUnit) = combineQuantitiesWithConversion(mergedItem.originalItems)
                consolidated.numericValue = combinedValue
                consolidated.standardUnit = combinedUnit
                consolidated.isParseable = true
                consolidated.parseConfidence = 1.0
                
                // NEW: Enhanced source tracking
                let sourceNote = mergedItem.isConverted ? "merged+converted" : "merged"
                consolidated.source = "\(sourceNote)(\(mergedItem.sourceCount))"
                consolidated.isCompleted = false
                consolidated.weeklyList = list
                // M9.15: GroceryListItem is now HouseholdScoped — inherit from parent WeeklyList
                consolidated.household = list.household
                consolidated.householdKey = list.householdKey
                
                // Use category from first item
                consolidated.categoryEntity = mergedItem.originalItems.first?.categoryEntity
                consolidated.sortOrder = mergedItem.originalItems.first?.sortOrder ?? 0
                
                // Delete original items
                mergedItem.originalItems.forEach { context.delete($0) }
            }
        }
        
        try context.save()
        
        lastMergeTime = Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Formatting (Reuses RecipeScalingService Pattern)
    
    private func formatMergedQuantity(value: Double, unit: String?) -> String {
        let fractionString = formatToFraction(value)
        if let unit = unit, !unit.isEmpty {
            return "\(fractionString) \(unit)"
        }
        return fractionString
    }
    
    private func formatToFraction(_ value: Double) -> String {
        let whole = Int(value)
        let fractional = value - Double(whole)
        
        // Common kitchen fractions with tolerance
        let fractions: [(value: Double, display: String)] = [
            (0.125, "1/8"), (0.166, "1/6"), (0.25, "1/4"),
            (0.333, "1/3"), (0.375, "3/8"), (0.5, "1/2"),
            (0.625, "5/8"), (0.666, "2/3"), (0.75, "3/4"),
            (0.833, "5/6"), (0.875, "7/8")
        ]
        
        let tolerance = 0.05
        
        for (fValue, fDisplay) in fractions {
            if abs(fractional - fValue) < tolerance {
                return whole > 0 ? "\(whole) \(fDisplay)" : fDisplay
            }
        }
        
        // No close fraction match
        if whole > 0 {
            return fractional < 0.01 ? "\(whole)" : String(format: "%.1f", value)
        }
        return String(format: "%.2f", value)
    }
}

// MARK: - Data Structures

struct MergeAnalysis {
    let list: WeeklyList?
    let groups: [MergeGroup]
    let totalSavings: Int
    
    var hasMergeOpportunities: Bool {
        return totalSavings > 0
    }
    
    var summary: String {
        if totalSavings == 0 {
            return "No duplicate items to consolidate"
        } else if totalSavings == 1 {
            return "Can consolidate 1 duplicate item"
        } else {
            return "Can consolidate \(totalSavings) duplicate items"
        }
    }
}

struct MergeGroup: Identifiable {
    let id = UUID()
    let ingredientName: String
    let originalCount: Int
    let mergedItems: [MergedItem]
    let savingsCount: Int
    
    var resultCount: Int {
        return mergedItems.count
    }
}

struct MergedItem: Identifiable {
    let id = UUID()
    let displayText: String
    let sourceCount: Int
    let sources: [String]
    let originalItems: [GroceryListItem]
    let isMerged: Bool
    let isConverted: Bool  // NEW: Flag if unit conversion was used
}

enum MergeError: Error {
    case invalidList
    case saveFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidList:
            return "Invalid grocery list"
        case .saveFailed:
            return "Failed to save consolidated items"
        }
    }
}
