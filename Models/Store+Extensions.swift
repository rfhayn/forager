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
        return color ?? "#7A7368"
    }

    public override func awakeFromInsert() {
        super.awakeFromInsert()
    }
}
