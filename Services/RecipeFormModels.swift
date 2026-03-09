//
//  RecipeFormModels.swift
//  forager
//
//  Created for M2.3: Recipe Creation & Editing
//  Data models for recipe creation and editing forms
//

import Foundation
import CoreData

// MARK: - Ingredient Input Model

enum IngredientStatus {
    case ready           // Has template with category
    case needsCategory   // Has template but no category
    case needsTemplate   // No template yet
    
    var indicator: String {
        switch self {
        case .ready: return "✓"
        case .needsCategory: return "?"
        case .needsTemplate: return "○"
        }
    }
    
    var color: String {
        switch self {
        case .ready: return "green"
        case .needsCategory: return "orange"
        case .needsTemplate: return "gray"
        }
    }
    
    var description: String {
        switch self {
        case .ready: return "Ready"
        case .needsCategory: return "Needs category"
        case .needsTemplate: return "New ingredient"
        }
    }
}

struct IngredientInput: Identifiable, Equatable {
    let id: UUID
    var fullText: String
    var template: IngredientTemplate?  // READ-ONLY reference
    var matchedViaAutocomplete: Bool

    // M8.4 Phase 7: Original state tracking for correction telemetry
    var originalFullText: String?          // Change detection (was text modified?)
    var originalNumericValue: Double?       // Original quantity from entity
    var originalStandardUnit: String?       // Original unit from entity
    var originalParseConfidence: Float?     // Original confidence from entity

    init(id: UUID = UUID(), fullText: String = "", template: IngredientTemplate? = nil, matchedViaAutocomplete: Bool = false,
         originalFullText: String? = nil, originalNumericValue: Double? = nil, originalStandardUnit: String? = nil, originalParseConfidence: Float? = nil) {
        self.id = id
        self.fullText = fullText
        self.template = template
        self.matchedViaAutocomplete = matchedViaAutocomplete
        self.originalFullText = originalFullText
        self.originalNumericValue = originalNumericValue
        self.originalStandardUnit = originalStandardUnit
        self.originalParseConfidence = originalParseConfidence
    }
    
    var statusIndicator: IngredientStatus {
        if template == nil {
            return .needsTemplate
        } else if template?.categoryEntity == nil {
            return .needsCategory
        } else {
            return .ready
        }
    }
    
    var hasCategory: Bool {
        guard let template = template else { return false }
        guard let category = template.categoryEntity?.name else { return false }
        return !category.isEmpty && category.lowercased() != "uncategorized"
    }
    
    static func == (lhs: IngredientInput, rhs: IngredientInput) -> Bool {
        return lhs.id == rhs.id &&
               lhs.fullText == rhs.fullText &&
               lhs.template?.objectID == rhs.template?.objectID &&
               lhs.matchedViaAutocomplete == rhs.matchedViaAutocomplete &&
               lhs.originalFullText == rhs.originalFullText &&
               lhs.originalNumericValue == rhs.originalNumericValue &&
               lhs.originalStandardUnit == rhs.originalStandardUnit &&
               lhs.originalParseConfidence == rhs.originalParseConfidence
    }
}

// MARK: - Recipe Form Data

struct RecipeFormData {
    var name: String = ""
    var prepTime: Int = 0
    var cookTime: Int = 0
    var servings: Int = 4
    var instructions: String = ""
    var tags: String = ""
    var isFavorite: Bool = false
    var ingredients: [IngredientInput] = []
    
    var totalTime: Int {
        return prepTime + cookTime
    }
    
    var hasBasicInfo: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasIngredients: Bool {
        return !ingredients.isEmpty && ingredients.contains(where: { !$0.fullText.isEmpty })
    }
    
    var hasInstructions: Bool {
        return !instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func validate() -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Name validation
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            errors.append(.emptyName)
        } else if trimmedName.count < 3 {
            errors.append(.nameTooShort)
        } else if trimmedName.count > 100 {
            errors.append(.nameTooLong)
        }
        
        // Servings validation
        if servings < 1 {
            errors.append(.invalidServings)
        } else if servings > 99 {
            errors.append(.servingsTooLarge)
        }
        
        // Time validation
        if prepTime < 0 || cookTime < 0 {
            errors.append(.negativeTimes)
        }
        if prepTime > 1440 || cookTime > 1440 {
            errors.append(.timesTooLarge)
        }
        
        // Ingredients validation
        let nonEmptyIngredients = ingredients.filter { !$0.fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if nonEmptyIngredients.isEmpty {
            errors.append(.noIngredients)
        } else if nonEmptyIngredients.count > 50 {
            errors.append(.tooManyIngredients)
        }
        
        // Instructions validation
        if instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.noInstructions)
        } else if instructions.count > 5000 {
            errors.append(.instructionsTooLong)
        }
        
        return errors
    }
    
    var uncategorizedTemplates: [IngredientTemplate] {
        return ingredients.compactMap { ingredientInput in
            guard let template = ingredientInput.template else { return nil }
            guard template.categoryEntity == nil else { return nil }
            return template
        }
    }
}

// MARK: - Validation Errors

enum ValidationError: LocalizedError {
    case emptyName
    case nameTooShort
    case nameTooLong
    case invalidServings
    case servingsTooLarge
    case negativeTimes
    case timesTooLarge
    case noIngredients
    case tooManyIngredients
    case noInstructions
    case instructionsTooLong
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Recipe name is required"
        case .nameTooShort:
            return "Recipe name must be at least 3 characters"
        case .nameTooLong:
            return "Recipe name must be less than 100 characters"
        case .invalidServings:
            return "Servings must be at least 1"
        case .servingsTooLarge:
            return "Servings must be less than 100"
        case .negativeTimes:
            return "Times cannot be negative"
        case .timesTooLarge:
            return "Times must be less than 24 hours (1440 minutes)"
        case .noIngredients:
            return "At least one ingredient is required"
        case .tooManyIngredients:
            return "Maximum 50 ingredients allowed"
        case .noInstructions:
            return "Instructions are required"
        case .instructionsTooLong:
            return "Instructions must be less than 5000 characters"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .emptyName:
            return "Enter a name for your recipe"
        case .nameTooShort:
            return "Add more detail to the recipe name"
        case .nameTooLong:
            return "Shorten the recipe name"
        case .invalidServings:
            return "Set servings to 1 or more"
        case .servingsTooLarge:
            return "Reduce the number of servings"
        case .negativeTimes:
            return "Enter positive values for prep and cook times"
        case .timesTooLarge:
            return "Reduce prep and cook times"
        case .noIngredients:
            return "Add at least one ingredient"
        case .tooManyIngredients:
            return "Remove some ingredients or split into multiple recipes"
        case .noInstructions:
            return "Add instructions for preparing this recipe"
        case .instructionsTooLong:
            return "Shorten the instructions"
        }
    }
}
