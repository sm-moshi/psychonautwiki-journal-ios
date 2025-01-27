// Copyright (c) 2023. Isaak Hanimann.
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

enum AddIngestionDestination: Hashable {
    case interactions(substance: Substance)
    case saferUse(substance: Substance)
    case saferRoutes
}

extension AddIngestionDestination: Equatable {
    static func == (lhs: AddIngestionDestination, rhs: AddIngestionDestination) -> Bool {
        switch (lhs, rhs) {
        case (.interactions(let lhs), .interactions(let rhs)):
            return lhs == rhs
        case (.saferUse(let lhs), .saferUse(let rhs)):
            return lhs == rhs
        case (.saferRoutes, .saferRoutes):
            return true
        default:
            return false
        }
    }
}

extension AddIngestionDestination {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .interactions(let substance):
            hasher.combine(0)
            hasher.combine(substance)
        case .saferUse(let substance):
            hasher.combine(1)
            hasher.combine(substance)
        case .saferRoutes:
            hasher.combine(2)
        }
    }
}
