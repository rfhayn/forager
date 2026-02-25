//
//  IngredientTemplate+Validation.swift
//  forager
//
//  Created for M3.5 Phase 1 Task 3: Template Validation
//  Date: October 22, 2025
//
//  Purpose: Add Core Data validation rules to IngredientTemplate entity
//  Note: IngredientTemplate uses Class Definition codegen, so validation added via extension
//

import Foundation
import CoreData

extension IngredientTemplate {
    
    // MARK: - Validation Methods
    
    /// Validates template data before insert
    /// Called automatically by Core Data when new template is inserted
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateTemplateData()
    }
    
    /// Validates template data before update
    /// Called automatically by Core Data when template is updated
    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateTemplateData()
    }
    
    /// Core validation logic for template data
    internal func validateTemplateData() throws {
        // Validate name
        try validateName()
        
        // Validate category
        try validateCategory()
        
        // Validate usage count
        try validateUsageCount()
        
        // Validate date created
        try validateDateCreated()
    }
    
    // MARK: - Individual Field Validation
    
    private func validateName() throws {
        guard let name = self.name else {
            throw ValidationError.nameRequired
        }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            throw ValidationError.nameEmpty
        }
        
        if trimmedName.count < 2 {
            throw ValidationError.nameTooShort
        }
        
        if trimmedName.count > 250 {
            throw ValidationError.nameTooLong
        }
        
        // M7.1.3: Duplicate checking removed - now handled by IngredientTemplateRepository
        // Repository pattern enforces semantic uniqueness via canonicalName
        // This validation layer only checks basic field constraints
    }
    
    private func validateCategory() throws {
        // Category is optional, but if provided, must be valid
        if let category = self.category {
            let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedCategory.isEmpty {
                // Empty string not allowed - should be nil instead
                throw ValidationError.categoryEmpty
            }
            
            if trimmedCategory.count > 50 {
                throw ValidationError.categoryTooLong
            }
        }
        // nil category is valid (uncategorized)
    }
    
    private func validateUsageCount() throws {
        if self.usageCount < 0 {
            throw ValidationError.negativeUsageCount
        }
        
        // Sanity check: usage count shouldn't be unreasonably high
        if self.usageCount > 10000 {
            throw ValidationError.usageCountTooHigh
        }
    }
    
    private func validateDateCreated() throws {
        guard let dateCreated = self.dateCreated else {
            throw ValidationError.dateCreatedRequired
        }
        
        // Date should not be in the future
        if dateCreated > Date() {
            throw ValidationError.dateCreatedInFuture
        }
        
        // Date should not be unreasonably old (before 2020)
        let oldestAllowedDate = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 1))!
        if dateCreated < oldestAllowedDate {
            throw ValidationError.dateCreatedTooOld
        }
    }
    
    // MARK: - M8.3.1: Template Quality Heuristics

    /// Detects template names that likely contain leaked quantities, units, or qualifiers.
    /// Used to show a yellow review badge on the Ingredients tab so users can clean up
    /// problematic names that slipped through parsing.
    var needsReview: Bool {
        guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else { return false }

        let lower = name.lowercased()

        // 1. Contains parenthetical text — e.g. "butter (room temperature, about 2 tbsp)"
        if name.contains("(") { return true }

        // 2. Contains digits or Unicode fraction characters
        // Exception: product variants where % follows a digit (e.g. "2% milk", "1% milk")
        let fractions = CharacterSet(charactersIn: "½⅓¼⅔¾⅛⅜⅝⅞")
        let hasDigit = name.unicodeScalars.contains(where: { CharacterSet.decimalDigits.contains($0) || fractions.contains($0) })
        if hasDigit {
            let isProductVariant = lower.range(of: #"^\d+%\s+\w+"#, options: .regularExpression) != nil
                || lower.range(of: #"\w+\s+\d+%$"#, options: .regularExpression) != nil
            if !isProductVariant {
                return true
            }
        }

        // 3. Ends with qualifier phrases — e.g. "herbs to garnish", "salt to taste"
        let qualifierSuffixes = [
            "to taste", "to garnish", "as needed", "for serving",
            "for garnish", "as desired", "to serve", "for topping"
        ]
        for suffix in qualifierSuffixes {
            if lower.hasSuffix(suffix) { return true }
        }

        // 4. First word is a known unit/measure — e.g. "loaf french bread", "can tomatoes"
        let words = lower.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if words.count > 1 {
            let unitPrefixes: Set<String> = [
                "loaf", "loaves", "bunch", "bunches", "head", "heads",
                "sprig", "sprigs", "slice", "slices", "piece", "pieces",
                "can", "cans", "jar", "jars", "bag", "bags",
                "package", "packages", "box", "boxes", "bottle", "bottles",
                "cup", "cups", "tablespoon", "tablespoons", "tbsp",
                "teaspoon", "teaspoons", "tsp", "pinch", "dash", "handful"
            ]
            if let firstWord = words.first, unitPrefixes.contains(firstWord) {
                return true
            }
        }

        return false
    }

    // MARK: - Computed Properties for Common Queries

    /// Returns true if template has a category assigned
    var hasCategory: Bool {
        return category != nil && !(category?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? false)
    }
    
    /// Returns true if template is marked as a staple
    var isStapleItem: Bool {
        return isStaple
    }
    
    /// Returns true if template has been used at least once
    var hasBeenUsed: Bool {
        return usageCount > 0
    }
    
    /// Returns true if template is frequently used (10+ uses)
    var isFrequentlyUsed: Bool {
        return usageCount >= 10
    }
    
    /// Returns display name with proper formatting
    var displayName: String {
        return name ?? "Unknown Ingredient"
    }
    
    /// Returns category display name with proper formatting
    var displayCategory: String {
        return category ?? "Uncategorized"
    }
    
    /// Returns formatted usage description
    var usageDescription: String {
        switch usageCount {
        case 0:
            return "Never used"
        case 1:
            return "Used once"
        case 2...9:
            return "Used \(usageCount) times"
        case 10...49:
            return "Used often (\(usageCount))"
        default:
            return "Frequently used (\(usageCount))"
        }
    }
    
    /// Returns true if template has valid data for all required fields
    var isValid: Bool {
        do {
            try validateTemplateData()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Validation Error Types
    
    enum ValidationError: LocalizedError {
        case nameRequired
        case nameEmpty
        case nameTooShort
        case nameTooLong
        case duplicateName(String)
        case categoryEmpty
        case categoryTooLong
        case negativeUsageCount
        case usageCountTooHigh
        case dateCreatedRequired
        case dateCreatedInFuture
        case dateCreatedTooOld
        
        var errorDescription: String? {
            switch self {
            case .nameRequired:
                return "Ingredient template name is required"
            case .nameEmpty:
                return "Ingredient template name cannot be empty"
            case .nameTooShort:
                return "Ingredient template name must be at least 2 characters"
            case .nameTooLong:
                return "Ingredient template name cannot exceed 250 characters"
            case .duplicateName(let name):
                return "An ingredient template named '\(name)' already exists"
            case .categoryEmpty:
                return "Category cannot be an empty string (use nil for uncategorized)"
            case .categoryTooLong:
                return "Category name cannot exceed 50 characters"
            case .negativeUsageCount:
                return "Usage count cannot be negative"
            case .usageCountTooHigh:
                return "Usage count exceeds reasonable limit (10,000)"
            case .dateCreatedRequired:
                return "Date created is required"
            case .dateCreatedInFuture:
                return "Date created cannot be in the future"
            case .dateCreatedTooOld:
                return "Date created cannot be before 2020"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .nameRequired, .nameEmpty:
                return "Provide a valid ingredient name"
            case .nameTooShort:
                return "Use a longer, more descriptive name"
            case .nameTooLong:
                return "Shorten the ingredient name to 250 characters or less"
            case .duplicateName:
                return "Use the existing template or choose a different name"
            case .categoryEmpty:
                return "Set category to nil or provide a valid category name"
            case .categoryTooLong:
                return "Shorten the category name"
            case .negativeUsageCount:
                return "Reset usage count to 0 or a positive number"
            case .usageCountTooHigh:
                return "Verify the usage count is correct"
            case .dateCreatedRequired:
                return "Set date created to current date"
            case .dateCreatedInFuture:
                return "Set date created to current date or earlier"
            case .dateCreatedTooOld:
                return "Verify the date created is correct"
            }
        }
    }
}

// MARK: - Debug Description

extension IngredientTemplate {
    /// Returns detailed debug description of template
    public override var debugDescription: String {
        return """
        IngredientTemplate {
            id: \(id?.uuidString ?? "nil")
            name: \(name ?? "nil")
            category: \(category ?? "nil")
            isStaple: \(isStaple)
            usageCount: \(usageCount)
            dateCreated: \(dateCreated?.description ?? "nil")
            isValid: \(isValid)
        }
        """
    }
}
