import Foundation
import CoreData

extension JournalScreen {
    @MainActor
    class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        @Published var currentExperiences: [Experience] = []
        @Published var previousExperiences: [Experience] = []
        @Published var searchText = "" {
            didSet {
                setupFetchRequestPredicateAndFetch()
            }
        }
        @Published var isShowingAddIngestionSheet = false
        @Published var isTimeRelative = false
        @Published var isFavoriteFilterEnabled = false {
            didSet {
                setupFetchRequestPredicateAndFetch()
            }
        }
        private let experienceFetchController: NSFetchedResultsController<Experience>!

        override init() {
            let fetchRequest = Experience.fetchRequest()
            fetchRequest.sortDescriptors = [ NSSortDescriptor(keyPath: \Experience.sortDate, ascending: false) ]
            experienceFetchController = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: PersistenceController.shared.viewContext,
                sectionNameKeyPath: nil, cacheName: nil
            )
            super.init()
            experienceFetchController.delegate = self
            do {
                try experienceFetchController.performFetch()
                let experiences = experienceFetchController?.fetchedObjects ?? []
                splitExperiencesInCurrentAndPrevious(experiences: experiences)
            } catch {
                NSLog("Error: could not fetch Experiences")
            }
        }

        private func splitExperiencesInCurrentAndPrevious(experiences: [Experience]) {
            self.currentExperiences = experiences.prefix(while: { exp in
                exp.isCurrent
            })
            self.previousExperiences = experiences.suffix(experiences.count-currentExperiences.count)
        }

        func createManyExperiencesAndIngestions() {
            let context = PersistenceController.shared.viewContext
            let cocaine = SubstanceCompanion(context: context)
            cocaine.substanceName = "Cocaine"
            cocaine.colorAsText = SubstanceColor.blue.rawValue
            let mdma = SubstanceCompanion(context: context)
            mdma.substanceName = "MDMA"
            mdma.colorAsText = SubstanceColor.pink.rawValue
            let ketamine = SubstanceCompanion(context: context)
            ketamine.substanceName = "Ketamine"
            ketamine.colorAsText = SubstanceColor.green.rawValue
            let heroin = SubstanceCompanion(context: context)
            heroin.substanceName = "Heroin"
            heroin.colorAsText = SubstanceColor.yellow.rawValue
            for experienceIndex in 0...5000 {
                let experienceDifference: TimeInterval = 30 * 60 * 60
                let newExperience = Experience(context: context)
                let experienceStart = Date(timeIntervalSinceNow: -(Double(experienceIndex)*experienceDifference))
                newExperience.creationDate = experienceStart
                newExperience.sortDate = experienceStart
                newExperience.title = experienceStart.asDateString
                newExperience.isFavorite = false
                newExperience.creationDate = experienceStart
                newExperience.text = "Same note for everything"

                let ingestionTimeCocaine = experienceStart
                let ingestionCocaine = Ingestion(context: context)
                ingestionCocaine.identifier = UUID()
                ingestionCocaine.time = ingestionTimeCocaine
                ingestionCocaine.creationDate = ingestionTimeCocaine
                ingestionCocaine.dose = 30
                ingestionCocaine.units = "mg"
                ingestionCocaine.isEstimate = false
                ingestionCocaine.note = "Some note"
                ingestionCocaine.administrationRoute = AdministrationRoute.insufflated.rawValue
                ingestionCocaine.substanceName = "Cocaine"
                ingestionCocaine.color = SubstanceColor.blue.rawValue
                ingestionCocaine.experience = newExperience
                ingestionCocaine.substanceCompanion = cocaine

                let ingestionTimeMDMA = experienceStart + 60 * 60
                let ingestionMDMA = Ingestion(context: context)
                ingestionMDMA.identifier = UUID()
                ingestionMDMA.time = ingestionTimeMDMA
                ingestionMDMA.creationDate = ingestionTimeMDMA
                ingestionMDMA.dose = 50
                ingestionMDMA.units = "mg"
                ingestionMDMA.isEstimate = false
                ingestionMDMA.note = "Some note"
                ingestionMDMA.administrationRoute = AdministrationRoute.oral.rawValue
                ingestionMDMA.substanceName = "MDMA"
                ingestionMDMA.color = SubstanceColor.blue.rawValue
                ingestionMDMA.experience = newExperience
                ingestionMDMA.substanceCompanion = mdma

                let ingestionTimeMDMA2 = experienceStart + 2 * 60 * 60
                let ingestionMDMA2 = Ingestion(context: context)
                ingestionMDMA2.identifier = UUID()
                ingestionMDMA2.time = ingestionTimeMDMA2
                ingestionMDMA2.creationDate = ingestionTimeMDMA2
                ingestionMDMA2.dose = 50
                ingestionMDMA2.units = "mg"
                ingestionMDMA2.isEstimate = false
                ingestionMDMA2.note = "Some note"
                ingestionMDMA2.administrationRoute = AdministrationRoute.oral.rawValue
                ingestionMDMA2.substanceName = "MDMA"
                ingestionMDMA2.color = SubstanceColor.blue.rawValue
                ingestionMDMA2.experience = newExperience
                ingestionMDMA2.substanceCompanion = mdma

                let ingestionTimeKeta = experienceStart + 3 * 60 * 60
                let ingestionKeta = Ingestion(context: context)
                ingestionKeta.identifier = UUID()
                ingestionKeta.time = ingestionTimeKeta
                ingestionKeta.creationDate = ingestionTimeKeta
                ingestionKeta.dose = 20
                ingestionKeta.units = "mg"
                ingestionKeta.isEstimate = false
                ingestionKeta.note = "Some note"
                ingestionKeta.administrationRoute = AdministrationRoute.insufflated.rawValue
                ingestionKeta.substanceName = "Ketamine"
                ingestionKeta.color = SubstanceColor.blue.rawValue
                ingestionKeta.experience = newExperience
                ingestionKeta.substanceCompanion = ketamine

                let ingestionTimeHeroin = experienceStart + 4 * 60 * 60
                let ingestionHeroin = Ingestion(context: context)
                ingestionHeroin.identifier = UUID()
                ingestionHeroin.time = ingestionTimeHeroin
                ingestionHeroin.creationDate = ingestionTimeHeroin
                ingestionHeroin.dose = 30
                ingestionHeroin.units = "mg"
                ingestionHeroin.isEstimate = false
                ingestionHeroin.note = "Some note"
                ingestionHeroin.administrationRoute = AdministrationRoute.insufflated.rawValue
                ingestionHeroin.substanceName = "Heroin"
                ingestionHeroin.color = SubstanceColor.blue.rawValue
                ingestionHeroin.experience = newExperience
                ingestionHeroin.substanceCompanion = heroin
            }
            PersistenceController.shared.saveViewContext()
        }

        private func setupFetchRequestPredicateAndFetch() {
            experienceFetchController?.fetchRequest.predicate = getPredicate()
            try? experienceFetchController?.performFetch()
            let experiences = experienceFetchController?.fetchedObjects ?? []
            splitExperiencesInCurrentAndPrevious(experiences: experiences)
        }

        private func getPredicate() -> NSPredicate? {
            let predicateFavorite = NSPredicate(
                format: "isFavorite == %@",
                NSNumber(value: true)
            )
            let predicateTitle = NSPredicate(
                format: "title CONTAINS[cd] %@",
                searchText as CVarArg
            )
            let predicateSubstance = NSPredicate(
                format: "%K.%K CONTAINS[cd] %@",
                #keyPath(Experience.ingestions),
                #keyPath(Ingestion.substanceName),
                searchText as CVarArg
            )
            if isFavoriteFilterEnabled {
                if searchText.isEmpty {
                    return predicateFavorite
                } else {
                    let titleOrSubstancePredicate = NSCompoundPredicate(
                        orPredicateWithSubpredicates: [predicateTitle, predicateSubstance]
                    )
                    return NSCompoundPredicate(andPredicateWithSubpredicates: [predicateFavorite, titleOrSubstancePredicate])
                }
            } else {
                if searchText.isEmpty {
                    return nil
                } else {
                    return NSCompoundPredicate(
                        orPredicateWithSubpredicates: [predicateTitle, predicateSubstance]
                    )
                }
            }
        }

        nonisolated public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            guard let exps = controller.fetchedObjects as? [Experience] else {return}
            Task {
                await MainActor.run {
                    splitExperiencesInCurrentAndPrevious(experiences: exps)
                }
            }
        }

        func delete(experience: Experience) {
            let viewContext = PersistenceController.shared.viewContext
            viewContext.delete(experience)
            if viewContext.hasChanges {
                try? viewContext.save()
            }
        }
    }
}
