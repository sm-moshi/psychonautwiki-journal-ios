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
import AppIntents

// swiftlint:disable type_body_length
struct ExperienceScreen: View {
    @ObservedObject var experience: Experience

    @FetchRequest private var ingestions: FetchedResults<Ingestion>
    @FetchRequest private var shulginRatings: FetchedResults<ShulginRating>
    @FetchRequest private var timedNotes: FetchedResults<TimedNote>

    init(experience: Experience) {
        self.experience = experience
        _ingestions = FetchRequest(
            entity: Ingestion.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Ingestion.time, ascending: false)],
            predicate: NSPredicate(format: "experience == %@", experience)
        )
        _shulginRatings = FetchRequest(
            entity: ShulginRating.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \ShulginRating.time, ascending: false)],
            predicate: NSPredicate(format: "experience == %@", experience)
        )
        _timedNotes = FetchRequest(
            entity: TimedNote.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \TimedNote.time, ascending: false)],
            predicate: NSPredicate(format: "experience == %@", experience)
        )
    }

    @AppStorage(PersistenceController.timeDisplayStyleKey) private var timeDisplayStyleText: String = SaveableTimeDisplayStyle.auto.rawValue

    private var saveableTimeDisplayStyle: Binding<SaveableTimeDisplayStyle> {
        Binding(
            get: {
                SaveableTimeDisplayStyle(rawValue: timeDisplayStyleText) ?? .regular
            },
            set: { newValue in timeDisplayStyleText = newValue.rawValue }
        )
    }

    var timeDisplayStyle: TimeDisplayStyle {
        switch saveableTimeDisplayStyle.wrappedValue {
        case .regular:
            return .regular
        case .relativeToNow:
            return .relativeToNow
        case .relativeToStart:
            return .relativeToStart
        case .between:
            return .between
        case .auto:
            if experience.isCurrent {
                return .relativeToNow
            } else {
                return .regular
            }
        }
    }

    @State private var isShowingDeleteConfirmation = false
    @State private var sheetToShow: SheetOption?
    @State private var hiddenIngestions: [ObjectIdentifier] = []
    @State private var hiddenRatings: [ObjectIdentifier] = []
    @State private var myTimelineModel: TimelineModel?
    @State private var myCumulativeDoses: [CumulativeDose] = []
    @State private var chartData: ChartData?
    @State private var consumersWithIngestions: [ConsumerWithIngestions] = []
    @State private var interactions: [Interaction] = []
    @State private var substancesUsed: [Substance] = []

    private func calculateScreenInfo() {
        Task {
            let timelineModel = experience.getMyTimeLineModel(
                hiddenIngestions: hiddenIngestions,
                hiddenRatings: hiddenRatings,
                areRedosesDrawnIndividually: areRedosesDrawnIndividually,
                areSubstanceHeightsIndependent: areSubstanceHeightsIndependent
            )
            self.myTimelineModel = timelineModel
            self.myCumulativeDoses = experience.myCumulativeDoses
            self.chartData = experience.getChartData()
            self.consumersWithIngestions = experience.getConsumers(hiddenIngestions: hiddenIngestions, areRedosesDrawnIndividually: areRedosesDrawnIndividually, areSubstanceHeightsIndependent: areSubstanceHeightsIndependent)
            self.interactions = experience.getInteractions()
            self.substancesUsed = experience.getSubstancesUsed()
        }
    }

    @AppStorage(PersistenceController.isEyeOpenKey2) var isEyeOpen: Bool = false
    @AppStorage(PersistenceController.isHidingDosageDotsKey) var isHidingDosageDots: Bool = false
    @AppStorage(PersistenceController.isHidingToleranceChartInExperienceKey) var isHidingToleranceChartInExperience: Bool = false
    @AppStorage(PersistenceController.isHidingSubstanceInfoInExperienceKey) var isHidingSubstanceInfoInExperience: Bool = false
    @AppStorage(PersistenceController.areRedosesDrawnIndividuallyKey) var areRedosesDrawnIndividually: Bool = false
    @AppStorage(PersistenceController.independentSubstanceHeightKey) var areSubstanceHeightsIndependent: Bool = false
    @AppStorage("isOpenLastExperienceSiriTipVisible") private var isSiriTipVisible = true

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var locationManager: LocationManager

    enum SheetOption: Identifiable, Hashable {
        case editTitle
        case editNotes
        case editLocation(experienceLocation: ExperienceLocation)
        case addLocation
        case addRating
        case addTimedNote
        case editTimedNote(timedNote: TimedNote)
        case editIngestion(ingestion: Ingestion)

        var id: Self {
            return self
        }
    }

    private func showIngestion(id: ObjectIdentifier) {
        hiddenIngestions.removeAll { hiddenID in
            hiddenID == id
        }
        updateActivityIfActive()
    }

    private func hideIngestion(id: ObjectIdentifier) {
        hiddenIngestions.append(id)
        updateActivityIfActive()
    }

    private func showRating(id: ObjectIdentifier) {
        hiddenRatings.removeAll { hiddenID in
            hiddenID == id
        }
        updateActivityIfActive()
    }

    private func hideRating(id: ObjectIdentifier) {
        hiddenRatings.append(id)
        updateActivityIfActive()
    }

    func updateActivityIfActive() {
        if #available(iOS 16.2, *) {
            if let lastTime = experience.myIngestionsSorted.last?.time, lastTime > Date.now.addingTimeInterval(-12 * 60 * 60) && ActivityManager.shared.isActivityActive {
                startOrUpdateLiveActivity()
            }
        }
    }

    @available(iOS 16.2, *)
    func startOrUpdateLiveActivity() {
        Task {
            await ActivityManager.shared.startOrUpdateActivity(
                substanceGroups: getSubstanceIngestionGroups(ingestions: experience.myIngestionsSorted.filter { !hiddenIngestions.contains($0.id) }),
                everythingForEachRating: experience.ratingsWithTimeSorted
                    .filter { !hiddenRatings.contains($0.id) }
                    .map { shulgin in
                        EverythingForOneRating(time: shulgin.timeUnwrapped, option: shulgin.optionUnwrapped)
                    },
                everythingForEachTimedNote: experience.timedNotesForTimeline,
                areRedosesDrawnIndividually: areRedosesDrawnIndividually,
                areSubstanceHeightsIndependent: areSubstanceHeightsIndependent
            )
        }
    }

    @available(iOS 16.2, *)
    func stopLiveActivity() {
        Task {
            await ActivityManager.shared.stopActivity(
                substanceGroups: getSubstanceIngestionGroups(ingestions: experience.myIngestionsSorted.filter { !hiddenIngestions.contains($0.id) }),
                everythingForEachRating: experience.ratingsWithTimeSorted
                    .filter { !hiddenRatings.contains($0.id) }
                    .map { shulgin in
                        EverythingForOneRating(time: shulgin.timeUnwrapped, option: shulgin.optionUnwrapped)
                    },
                everythingForEachTimedNote: experience.timedNotesForTimeline,
                areRedosesDrawnIndividually: areRedosesDrawnIndividually,
                areSubstanceHeightsIndependent: areSubstanceHeightsIndependent
            )
        }
    }

    private func addIngestion() {
        UserDefaults.standard.set(experience.ingestionsSorted.last?.time?.timeIntervalSince1970, forKey: PersistenceController.lastIngestionTimeOfExperienceWhereAddIngestionTappedKey)
        Navigator.shared.showAddIngestionFullScreenCover() // can't use Navigator as environment object because for some reason this messes up the layout of this screen
    }


    var body: some View {
        FabPosition {
            let threeHours: TimeInterval = 3*60*60
            if experience.isCurrent || experience.creationDateUnwrapped.distance(to: .now) < threeHours {
                Button(action: addIngestion) {
                    Label("New Ingestion", systemImage: "plus").labelStyle(FabLabelStyle())
                }
            }
        } screen: {
            List {
                if let myTimelineModel, !experience.myIngestionsSorted.isEmpty {
                    Section {
                        TimelineSection(
                            timelineModel: myTimelineModel,
                            editIngestion: { ingestionToEdit in
                                sheetToShow = .editIngestion(ingestion: ingestionToEdit)
                            },
                            ingestionsSorted: experience.myIngestionsSorted,
                            timeDisplayStyle: timeDisplayStyle,
                            isEyeOpen: isEyeOpen,
                            isHidingDosageDots: isHidingDosageDots,
                            hiddenIngestions: hiddenIngestions,
                            isCurrentExperience: experience.isCurrent
                        )
                        if #available(iOS 16.2, *) {
                            if experience.isCurrent && myTimelineModel.isWorthDrawing {
                                LiveActivityButton(
                                    stopLiveActivity: {
                                        stopLiveActivity()
                                    },
                                    startLiveActivity: {
                                        startOrUpdateLiveActivity()
                                    }
                                )
                            }
                        }
                    } header: {
                        HStack {
                            Text(experience.sortDateUnwrapped, format: Date.FormatStyle().day().month().year().weekday(.abbreviated))
                            Spacer()
                            NavigationLink(value: GlobalNavigationDestination.timeline(
                                timelineModel: myTimelineModel,
                                timeDisplayStyle: timeDisplayStyle)) {
                                    Label("Timeline screen", systemImage: "arrow.down.left.and.arrow.up.right.square").labelStyle(.iconOnly)
                                }
                        }
                    }
                    if !myCumulativeDoses.isEmpty && isEyeOpen {
                        Section("Your Cumulative Dose") {
                            ForEach(myCumulativeDoses) { cumulative in
                                if let substance = SubstanceRepo.shared.getSubstance(name: cumulative.substanceName) {
                                    NavigationLink(value: GlobalNavigationDestination.dose(substance: substance)) {
                                        CumulativeDoseRow(
                                            substanceName: cumulative.substanceName,
                                            substanceColor: cumulative.substanceColor,
                                            cumulativeRoutes: cumulative.cumulativeRoutes,
                                            isHidingDosageDots: isHidingDosageDots,
                                            isEyeOpen: isEyeOpen
                                        )
                                    }
                                } else {
                                    CumulativeDoseRow(
                                        substanceName: cumulative.substanceName,
                                        substanceColor: cumulative.substanceColor,
                                        cumulativeRoutes: cumulative.cumulativeRoutes,
                                        isHidingDosageDots: isHidingDosageDots,
                                        isEyeOpen: isEyeOpen
                                    )
                                }
                            }
                        }
                    }
                }
                let notes = experience.textUnwrapped
                if !notes.isEmpty {
                    Section("Notes") {
                        Text(notes)
                            .padding(.vertical, 5)
                            .onTapGesture {
                                sheetToShow = .editNotes
                            }
                    }
                }
                let timedNotesSorted = experience.timedNotesSorted
                if !timedNotesSorted.isEmpty {
                    Section("Timed Notes") {
                        ForEach(Array(timedNotesSorted.enumerated()), id: \.element) { index, timedNote in
                            let previousNote = timedNotesSorted[safe: index - 1]
                            let isFirstNote = index == 0
                            Button(action: {
                                sheetToShow = .editTimedNote(timedNote: timedNote)
                            }, label: {
                                let time = timedNote.timeUnwrapped
                                let firstIngestionTime = experience.ingestionsSorted.first?.time
                                TimedNoteRow(timedNote: timedNote) {
                                    if timeDisplayStyle == .relativeToNow {
                                        RelativeTimeText(date: timedNote.timeUnwrapped)
                                    } else if let firstIngestionTime, timeDisplayStyle == .relativeToStart {
                                        let dateComponents = DateDifference.between(firstIngestionTime, and: time)
                                        Text(DateDifference.formattedWithMax2Units(dateComponents)) + Text(" in")
                                    } else if let firstIngestionTime, timeDisplayStyle == .between {
                                        if isFirstNote {
                                            let dateComponents = DateDifference.between(firstIngestionTime, and: time)
                                            Text(DateDifference.formattedWithMax2Units(dateComponents)) + Text(" after first ingestion")
                                        } else if let previousNote {
                                            let dateComponents = DateDifference.between(previousNote.timeUnwrapped, and: time)
                                            Text(DateDifference.formattedWithMax2Units(dateComponents)) + Text(" later")
                                        }
                                    } else {
                                        Text(time, format: Date.FormatStyle().hour().minute().weekday(.abbreviated))
                                    }
                                }.foregroundColor(.primary) // to override the button styles
                            })
                        }
                    }
                }
                if isEyeOpen && !experience.ratingsUnwrapped.isEmpty {
                    ShulginRatingSection(
                        experience: experience,
                        hiddenRatings: hiddenRatings,
                        showRating: showRating,
                        hideRating: hideRating,
                        timeDisplayStyle: timeDisplayStyle,
                        firstIngestionTime: experience.ingestionsSorted.first?.timeUnwrapped
                    )
                }
                if let chartDataTolerence = chartData, !chartDataTolerence.toleranceWindows.isEmpty && !isHidingToleranceChartInExperience && isEyeOpen {
                    Section {
                        ToleranceChart(
                            toleranceWindows: chartDataTolerence.toleranceWindows,
                            numberOfRows: chartDataTolerence.numberOfSubstancesInToleranceChart,
                            timeOption: .onlyIfCurrentTimeInChart,
                            experienceStartDate: experience.sortDateUnwrapped.getDateWithoutTime(),
                            isTimeRelative: timeDisplayStyle == .relativeToNow
                        )
                    } header: {
                        HStack {
                            Text("Tolerance")
                            Spacer()
                            NavigationLink(value: GlobalNavigationDestination.toleranceTexts(substances: chartDataTolerence.substancesInChart)) {
                                Label("Tolerance info", systemImage: "doc.plaintext").labelStyle(.iconOnly)
                            }
                        }
                    } footer: {
                        if !chartDataTolerence.namesOfSubstancesWithMissingTolerance.isEmpty {
                            Text("Excluding ") + Text(chartDataTolerence.namesOfSubstancesWithMissingTolerance, format: .list(type: .and))
                        }
                    }
                }
                ForEach(consumersWithIngestions) { consumer in
                    let consumerTimelineModel = consumer.timelineModel
                    Section {
                        TimelineSection(
                            timelineModel: consumerTimelineModel,
                            editIngestion: { ingestionToEdit in
                                sheetToShow = .editIngestion(ingestion: ingestionToEdit)
                            },
                            ingestionsSorted: consumer.ingestionsSorted,
                            timeDisplayStyle: timeDisplayStyle,
                            isEyeOpen: isEyeOpen,
                            isHidingDosageDots: isHidingDosageDots,
                            hiddenIngestions: hiddenIngestions,
                            isCurrentExperience: experience.isCurrent
                        )
                    } header: {
                        HStack {
                            Text(consumer.consumerName)
                            Spacer()
                            NavigationLink(value: GlobalNavigationDestination.timeline(
                                timelineModel: consumerTimelineModel,
                                timeDisplayStyle: timeDisplayStyle)) {
                                    Label("Timeline screen", systemImage: "arrow.down.left.and.arrow.up.right.square").labelStyle(.iconOnly)
                                }
                        }
                    }
                }
                if isEyeOpen && !isHidingSubstanceInfoInExperience && !substancesUsed.isEmpty {
                    Section("Info") {
                        ForEach(substancesUsed) { substance in
                            NavigationLink(value: GlobalNavigationDestination.substance(substance: substance)) {
                                Label(substance.name, systemImage: "info.circle")
                            }
                        }
                        if substancesUsed.contains(where: { $0.isHallucinogen }) {
                            NavigationLink(value: GlobalNavigationDestination.saferHallucinogen) {
                                Label("Safer Hallucinogens", systemImage: "cross")
                            }
                        }
                        ForEach(interactions) { interaction in
                            NavigationLink(value: GlobalNavigationDestination.allInteractions(substancesToCheck: substancesUsed)) {
                                InteractionPairRow(
                                    aName: interaction.aName,
                                    bName: interaction.bName,
                                    interactionType: interaction.interactionType
                                )
                            }
                        }
                        if interactions.isEmpty {
                            NavigationLink(value: GlobalNavigationDestination.allInteractions(substancesToCheck: substancesUsed)) {
                                Label("See Interactions", systemImage: "exclamationmark.triangle")
                            }
                        }
                        if experience.isCurrent {
                            SiriTipView(intent: OpenLastExperienceIntent(), isVisible: $isSiriTipVisible)
                        }
                    }
                }
                if let location = experience.location {
                    Section {
                        EditLocationLinkAndMap(experienceLocation: location)
                    } header: {
                        HStack {
                            Text("Location")
                            Spacer()
                            Button {
                                sheetToShow = .editLocation(experienceLocation: location)
                            } label: {
                                Label("Edit Location", systemImage: "pencil")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }
                }
            }
            .sheet(
                item: $sheetToShow,
                onDismiss: {
                    updateActivityIfActive()
                },
                content: { sheet in
                    switch sheet {
                    case .addLocation:
                        AddLocationScreen(locationManager: locationManager, experience: experience)
                    case let .editLocation(experienceLocation):
                        EditLocationScreen(experienceLocation: experienceLocation, locationManager: locationManager)
                    case .editNotes:
                        EditNotesScreen(experience: experience)
                    case .editTitle:
                        EditTitleScreen(experience: experience)
                    case .addRating:
                        AddRatingScreen(experience: experience, canDefineOverall: experience.overallRating == nil)
                    case .addTimedNote:
                        AddTimedNoteScreen(experience: experience)
                    case let .editTimedNote(timedNote):
                        EditTimedNoteScreen(timedNote: timedNote, experience: experience)
                    case let .editIngestion(ingestion):
                        let isHidden = Binding(
                            get: { hiddenIngestions.contains(ingestion.id) },
                            set: { newIsHidden in
                                if newIsHidden {
                                    hideIngestion(id: ingestion.id)
                                } else {
                                    showIngestion(id: ingestion.id)
                                }
                            }
                        )
                        EditIngestionScreen(
                            ingestion: ingestion,
                            isHidden: isHidden)
                    }
                })
        }
        .onReceive(ingestions.publisher) { _ in
            calculateScreenInfo()
        }
        .onReceive(shulginRatings.publisher) { _ in
            calculateScreenInfo()
        }
        .onReceive(timedNotes.publisher) { _ in
            calculateScreenInfo()
        }
        .onChange(of: hiddenRatings) { _ in
            calculateScreenInfo()
        }
        .onChange(of: hiddenIngestions) { _ in
            calculateScreenInfo()
        }
        .navigationTitle(experience.titleUnwrapped)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ExperienceToolbarContent(
                    experience: experience,
                    saveableTimeDisplayStyle: saveableTimeDisplayStyle,
                    sheetToShow: $sheetToShow,
                    isShowingDeleteConfirmation: $isShowingDeleteConfirmation,
                    addIngestion: addIngestion
                )
            }
        }
        .confirmationDialog(
            "Delete Experience?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible,
            actions: {
                Button("Delete", role: .destructive) {
                    delete()
                }
                Button("Cancel", role: .cancel) {}
            },
            message: {
                Text("This will also delete all of its ingestions.")
            }
        )
    }

    private func delete() {
        PersistenceController.shared.viewContext.delete(experience)
        PersistenceController.shared.saveViewContext()
        if #available(iOS 16.2, *) {
            stopLiveActivity()
        }
        dismiss()
    }
}
// swiftlint:enable type_body_length
