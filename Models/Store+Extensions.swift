//
//  Store+Extensions.swift
//  forager
//
//  M18.1.0: Store computed properties and helpers
//

import Foundation
import CoreData

extension Store {

    var displayName: String {
        return name ?? "Unknown Store"
    }

    var displayColor: String {
        return color ?? "#757575"
    }

    public override func awakeFromInsert() {
        super.awakeFromInsert()
    }
}
