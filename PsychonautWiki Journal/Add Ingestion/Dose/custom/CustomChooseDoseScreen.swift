// Copyright (c) 2022. Isaak Hanimann.
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

import SwiftUI

struct CustomChooseDoseScreen: View {
    let arguments: CustomChooseDoseScreenArguments
    let dismiss: () -> Void
    @State private var doseText = ""
    @State private var dose: Double?
    @State private var isEstimate = false
    @State private var doseVariance: Double?
    @FocusState private var isDoseFieldFocused: Bool

    @FetchRequest(
        sortDescriptors: []
    ) private var customSubstances: FetchedResults<CustomSubstance>

    private var customSubstance: CustomSubstance? {
        customSubstances.first { substance in
            substance.nameUnwrapped == arguments.substanceName
        }
    }

    var body: some View {
        screen.toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                nextLink
            }
        }
    }

    private var nextLink: some View {
        NavigationLink(value: getDestinationArguments(dose: dose)) {
            NextLabel()
        }
    }

    func getDestinationArguments(dose: Double?) -> FinishIngestionScreenArguments {
        FinishIngestionScreenArguments(
            substanceName: arguments.substanceName,
            administrationRoute: arguments.administrationRoute,
            dose: dose,
            units: arguments.units,
            isEstimate: isEstimate,
            estimatedDoseVariance: doseVariance
        )
    }

    private var unknownDoseLink: some View {
        NavigationLink("Use Unknown Dose", value: getDestinationArguments(dose: nil))
    }

    @FocusState private var isEstimatedVarianceFocused: Bool

    private var screen: some View {
        Form {
            if let explanationUnwrapped = customSubstance?.explanationUnwrapped {
                Section {
                    Text(explanationUnwrapped)
                }
            }
            Section {
                HStack {
                    TextField("Enter Dose", text: $doseText)
                        .focused($isDoseFieldFocused)
                        .keyboardType(.decimalPad)
                        .onChange(of: doseText) { text in
                            dose = getDouble(from: text)
                        }
                    Text(arguments.units)
                }
                .font(.title)
                Toggle("Dose is an Estimate", isOn: $isEstimate)
                    .tint(.accentColor)
                    .onChange(of: isEstimate, perform: { newIsEstimate in
                        if newIsEstimate {
                            isEstimatedVarianceFocused = true
                        }
                    })
                if isEstimate {
                    HStack {
                        Image(systemName: "plusminus")
                        TextField(
                            "Pure dose variance",
                            value: $doseVariance,
                            format: .number
                        )
                        .keyboardType(.decimalPad)
                        .focused($isEstimatedVarianceFocused)
                        Spacer()
                        Text(arguments.units)
                    }
                }
                unknownDoseLink
            }.listRowSeparator(.hidden)
        }
        .task {
            isDoseFieldFocused = true
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("\(arguments.substanceName) Dose")
    }
}

#Preview {
    NavigationStack {
        CustomChooseDoseScreen(
            arguments: .init(substanceName: "Coffee",
                             units: "cups",
                             administrationRoute: .oral),
            dismiss: {}
        )
    }
}
