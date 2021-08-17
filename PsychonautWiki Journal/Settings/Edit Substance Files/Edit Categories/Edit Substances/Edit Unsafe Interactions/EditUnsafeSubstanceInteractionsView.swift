import SwiftUI

struct EditUnsafeSubstanceInteractionsView: View {

    @ObservedObject var substance: Substance

    var body: some View {
        List {
            ForEach(substance.category!.file!.categoriesUnwrappedSorted) { category in
                if !category.substancesUnwrapped.isEmpty {
                    Section(header: Text(category.nameUnwrapped)) {
                        ForEach(category.sortedSubstancesUnwrapped) { substance in
                            getRowContent(for: substance)
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }

    private func getRowContent(for fileSubstance: Substance) -> some View {
        let isSelected = substance.unsafeSubstanceInteractionsUnwrapped.contains(fileSubstance)
        return Button(action: {
            if isSelected {
                substance.removeFromUnsafeSubstanceInteractions(fileSubstance)
            } else {
                substance.addToUnsafeSubstanceInteractions(fileSubstance)
            }
        }, label: {
            HStack {
                Text(fileSubstance.nameUnwrapped)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
        })
    }
}
