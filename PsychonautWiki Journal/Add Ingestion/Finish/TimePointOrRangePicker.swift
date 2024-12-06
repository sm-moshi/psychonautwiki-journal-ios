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

import SwiftUI

struct TimePointOrRangePicker: View {

    @Binding var selectedTimePickerOption: TimePickerOption
    @Binding var selectedTime: Date
    @Binding var selectedEndTime: Date

    var body: some View {
        Picker("Time picker option", selection: $selectedTimePickerOption.animation()) {
            Text("Time point").tag(TimePickerOption.pointInTime)
            Text("Time range").tag(TimePickerOption.timeRange)
        }.pickerStyle(.segmented)
        .labelsHidden()
        switch selectedTimePickerOption {
        case .pointInTime:
            HStack(alignment: .center) {
                DatePicker(
                    "Time",
                    selection: $selectedTime,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                Spacer()
                Button {
                    withAnimation {
                        selectedTime = Date.now
                    }
                } label: {
                    Label("Reset time", systemImage: "clock.arrow.circlepath").labelStyle(.iconOnly)
                }
            }
        case .timeRange:
            DatePicker(
                "Start time",
                selection: $selectedTime,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            DatePicker(
                "End time",
                selection: $selectedEndTime,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
        }

    }
}

enum TimePickerOption {
    case pointInTime, timeRange
}
