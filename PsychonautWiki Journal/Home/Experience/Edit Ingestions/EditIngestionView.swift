import SwiftUI

struct EditIngestionView: View {

    let ingestion: Ingestion

    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var calendarWrapper: CalendarWrapper

    @State private var selectedSubstance: Substance
    @State private var selectedAdministrationRoute: Roa.AdministrationRoute
    @State private var selectedDose: Double?
    @State private var selectedColor: Ingestion.IngestionColor
    @State private var selectedTime: Date
    @State private var isKeyboardShowing = false

    var doseInfo: DoseTypes? {
        selectedSubstance.getDose(for: selectedAdministrationRoute)
    }

    var selectedUnit: String? {
        doseInfo?.units
    }

    let colorColumns = [
        GridItem(.adaptive(minimum: 44))
    ]

    var isSubstanceDangerous: Bool {
        let dangerousIngestions = InteractionChecker.getDangerousIngestions(
            of: selectedSubstance,
            with: ingestion.experience!.sortedIngestionsUnwrapped
        )
        let dangerousInteractions = InteractionChecker.getDangerousInteraction(of: selectedSubstance)
        let isDangerous = !dangerousIngestions.isEmpty
            || !dangerousInteractions.isEmpty
        return isDangerous
    }

    var isSubstanceUnsafe: Bool {
        let unsafeIngestions = InteractionChecker.getUnsafeIngestions(
            of: selectedSubstance,
            with: ingestion.experience!.sortedIngestionsUnwrapped
        )
        let unsafeInteractions = InteractionChecker.getUnsafeInteraction(of: selectedSubstance)
        let isUnsafe = !unsafeIngestions.isEmpty
            || !unsafeInteractions.isEmpty
        return isUnsafe
    }

    var body: some View {
        Form {
            Section(header: Text("Substance")) {
                NavigationLink(
                    destination: SubstancePicker(
                        selectedSubstance: selectedSubstance,
                        substancesFile: selectedSubstance.category!.file!,
                        chooseSubstanceAndMoveOn: selectSubstance,
                        goBackOnSelect: true
                    )
                    .environmentObject(ingestion.experience!)
                ) {
                    HStack {
                        Text("Substance")
                        Spacer()
                        Text(selectedSubstance.nameUnwrapped)
                            .foregroundColor(.secondary)
                        if isSubstanceDangerous {
                            Image(systemName: "exclamationmark.3")
                                .foregroundColor(.red)
                        }
                        if isSubstanceUnsafe {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.yellow)
                        }
                    }
                }

                if selectedSubstance.roasUnwrapped.count > 1 {
                    Picker("Route of Administration", selection: $selectedAdministrationRoute) {
                        ForEach(selectedSubstance.administrationRoutesUnwrapped, id: \.self) { route in
                            Text(route.displayString).tag(route)
                        }
                    }
                }
            }

            Section(header: Text("Dose")) {
                DosePicker(
                    doseInfo: doseInfo,
                    doseMaybe: $selectedDose
                )
            }

            Section(header: Text("Time")) {
                DatePicker(
                    "Time",
                    selection: $selectedTime
                )
                .labelsHidden()
                .datePickerStyle(WheelDatePickerStyle())
            }

            Section(header: Text("Color")) {
                LazyVGrid(columns: colorColumns) {
                    ForEach(Ingestion.IngestionColor.allCases, id: \.self, content: colorButton)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Edit Ingestion")
        .onChange(of: selectedTime) { _ in update() }
        .onChange(of: selectedDose) { _ in update() }
        .onChange(of: selectedAdministrationRoute) { _ in update() }
        .onChange(of: selectedSubstance) { _ in update() }
        .onChange(of: selectedColor) { _ in update() }
        .onDisappear(perform: {
            let defaults = UserDefaults.standard
            defaults.setValue(selectedColor.rawValue, forKey: selectedSubstance.nameUnwrapped)
            ingestion.didChangeValue(for: \.substance)
            selectedSubstance.lastUsedDate = Date()
            if moc.hasChanges {
                calendarWrapper.createOrUpdateEventBeforeMocSave(from: ingestion.experience!)
                try? moc.save()
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation {
                isKeyboardShowing = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation {
                isKeyboardShowing = false
            }
        }
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
                if isKeyboardShowing {
                    Button("Done") {
                        hideKeyboard()
                        if moc.hasChanges {
                            try? moc.save()
                        }
                    }
                }
            }
        }
    }

    private func selectSubstance(chosenSubstance: Substance) {
        selectedAdministrationRoute = chosenSubstance.administrationRoutesUnwrapped.first!
        selectedDose = chosenSubstance.roasUnwrapped.first?.doseTypes?.common?.min
        selectedColor = getColorForSubstance(with: chosenSubstance.nameUnwrapped)
        self.selectedSubstance = chosenSubstance
    }

    private func getColorForSubstance(with name: String) -> Ingestion.IngestionColor {
        var color = Ingestion.IngestionColor.allCases.randomElement()!
        let defaults = UserDefaults.standard
        if let savedColorString = defaults.object(forKey: name) as? String {
            if let savedColor = Ingestion.IngestionColor(rawValue: savedColorString) {
                color = savedColor
            }
        }
        return color
    }

    private func colorButton(for color: Ingestion.IngestionColor) -> some View {
        ZStack {
            Color.from(ingestionColor: color)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(6)

            if color == selectedColor {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.white)
                    .font(.largeTitle)
            }
        }
        .onTapGesture {
            selectedColor = color
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(
            color == selectedColor
                ? [.isButton, .isSelected]
                : .isButton
        )
        .accessibilityLabel(LocalizedStringKey(color.rawValue))
    }

    init(ingestion: Ingestion) {
        self.ingestion = ingestion
        _selectedSubstance = State(wrappedValue: ingestion.substance!)
        _selectedAdministrationRoute = State(wrappedValue: ingestion.administrationRouteUnwrapped)
        _selectedDose = State(wrappedValue: ingestion.doseUnwrapped)
        _selectedColor = State(wrappedValue: ingestion.colorUnwrapped)
        _selectedTime = State(wrappedValue: ingestion.timeUnwrapped)
    }

    func update() {
        ingestion.experience?.objectWillChange.send()
        ingestion.time = selectedTime
        if let doseDouble = selectedDose {
            ingestion.dose = doseDouble
        }
        ingestion.administrationRoute = selectedAdministrationRoute.rawValue
        ingestion.substance = selectedSubstance
        ingestion.color = selectedColor.rawValue
    }
}

struct EditIngestionView_Previews: PreviewProvider {
    static var previews: some View {
        let helper = PersistenceController.preview.createPreviewHelper()
        EditIngestionView(ingestion: helper.experiences.first!.sortedIngestionsUnwrapped.first!)
            .environmentObject(helper.experiences.first!)
    }
}
