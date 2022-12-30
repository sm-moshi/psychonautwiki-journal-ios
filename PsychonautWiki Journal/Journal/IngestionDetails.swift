//
//  IngestionDetails.swift
//  PsychonautWiki Journal
//
//  Created by Isaak Hanimann on 30.12.22.
//

import Charts
import SwiftUI

@available(iOS 16, *)
struct IngestionDetailsChart: View {
    let data: [IngestionCount]
    let color: KeyValuePairs<String,Color>


    var body: some View {
        Chart(data) { element in
            BarMark(
                x: .value("Ingestions", element.ingestionCount),
                y: .value("Substance", element.substanceName)
            )
            .foregroundStyle(by: .value("Substance", element.substanceName))
        }
        .chartForegroundStyleScale(color)
    }
}

@available(iOS 16, *)
struct IngestionDetails: View {
    @State private var timeRange: TimeRange = .last30Days

    var data: [IngestionCount] {
        switch timeRange {
        case .last30Days:
            return IngestionData.last30Days
        case .last12Months:
            return IngestionData.last12Months
        }
    }

    var color: KeyValuePairs<String,Color> {
        switch timeRange {
        case .last30Days:
            return IngestionData.last30DaysColors
        case .last12Months:
            return IngestionData.last12MonthsColors
        }
    }

    var body: some View {
        List {
            VStack(alignment: .leading) {
                TimeRangePicker(value: $timeRange)
                    .padding(.bottom)
                Text("Most Ingested Substance")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(data.first?.substanceName ?? "Unknown")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                IngestionDetailsChart(data: data, color: color)
                    .frame(height: 300)
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationBarTitle("Style", displayMode: .inline)
    }
}

@available(iOS 16, *)
struct IngestionDetails_Previews: PreviewProvider {
    static var previews: some View {
        IngestionDetails()
    }
}
