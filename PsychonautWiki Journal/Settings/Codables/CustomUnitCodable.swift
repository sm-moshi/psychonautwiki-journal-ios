// Copyright (c) 2024. Isaak Hanimann.
// This file is part of PsychonautWiki Journal.
//
// PsychonautWiki Journal is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public Licence as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// PsychonautWiki Journal is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with PsychonautWiki Journal. If not, see https://www.gnu.org/licenses/gpl-3.0.en.html.

import Foundation

struct CustomUnitCodable: Codable {
    let id: Int
    let substanceName: String
    let name: String
    let creationDate: Date
    let administrationRoute: AdministrationRoute
    let dose: Double?
    let estimatedDoseVariance: Double?
    let isEstimate: Bool
    let isArchived: Bool
    let unit: String
    let originalUnit: String
    let note: String

    enum CodingKeys: String, CodingKey {
        case id
        case substanceName
        case name
        case creationDate
        case administrationRoute
        case dose
        case estimatedDoseVariance
        case isEstimate
        case isArchived
        case unit
        case originalUnit
        case note
    }

    init(
        id: Int,
        substanceName: String,
        name: String,
        creationDate: Date,
        administrationRoute: AdministrationRoute,
        dose: Double?,
        estimatedDoseVariance: Double?,
        isEstimate: Bool,
        isArchived: Bool,
        unit: String,
        originalUnit: String,
        note: String
    ) {
        self.id = id
        self.substanceName = substanceName
        self.name = name
        self.creationDate = creationDate
        self.administrationRoute = administrationRoute
        self.dose = dose
        self.estimatedDoseVariance = estimatedDoseVariance
        self.isEstimate = isEstimate
        self.isArchived = isArchived
        self.unit = unit
        self.originalUnit = originalUnit
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        substanceName = try values.decode(String.self, forKey: .substanceName)
        name = try values.decode(String.self, forKey: .name)
        let creationMillis = try values.decode(UInt64.self, forKey: .creationDate)
        creationDate = getDateFromMillis(millis: creationMillis)
        let routeString = try values.decode(String.self, forKey: .administrationRoute)
        if let route = AdministrationRoute(rawValue: routeString.lowercased()) {
            administrationRoute = route
        } else {
            throw try DecodingError.dataCorruptedError(in: decoder.unkeyedContainer(), debugDescription: "\(routeString) is not a valid route")
        }
        dose = try values.decodeIfPresent(Double.self, forKey: .dose)
        estimatedDoseVariance = try values.decodeIfPresent(Double.self, forKey: .estimatedDoseVariance)
        isEstimate = try values.decode(Bool.self, forKey: .isEstimate)
        isArchived = try values.decode(Bool.self, forKey: .isArchived)
        unit = try values.decode(String.self, forKey: .unit)
        originalUnit = try values.decode(String.self, forKey: .originalUnit)
        note = try values.decode(String.self, forKey: .note)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(substanceName, forKey: .substanceName)
        try container.encode(name, forKey: .name)
        try container.encode(UInt64(creationDate.timeIntervalSince1970) * 1000, forKey: .creationDate)
        try container.encode(administrationRoute.rawValue.uppercased(), forKey: .administrationRoute)
        try container.encode(dose, forKey: .dose)
        try container.encode(estimatedDoseVariance, forKey: .estimatedDoseVariance)
        try container.encode(isEstimate, forKey: .isEstimate)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encode(unit, forKey: .unit)
        try container.encode(originalUnit, forKey: .originalUnit)
        try container.encode(note, forKey: .note)
    }
}
