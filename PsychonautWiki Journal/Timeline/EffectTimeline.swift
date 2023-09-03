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

struct EffectTimeline: View {

    let timelineModel: TimelineModel
    var height: Double = 200
    var isShowingCurrentTime = true
    var spaceToLabels = 5.0
    private let lineWidth: Double = 5
    private var halfLineWidth: Double {
        lineWidth/2
    }

    var body: some View {
        VStack(spacing: 0) {
            timeLabels
            TimelineView(.everyMinute) { timeline in
                let timelineDate = timeline.date
                Canvas { context, size in
                    let pixelsPerSec = (size.width-halfLineWidth)/timelineModel.totalWidth
                    timelineModel.groupDrawables.forEach({ groupDrawable in
                        groupDrawable.draw(
                            context: context,
                            height: size.height,
                            pixelsPerSec: pixelsPerSec,
                            lineWidth: lineWidth)
                    })
                    timelineModel.ratingDrawables.forEach { ratingDrawable in
                        ratingDrawable.draw(
                            context: &context,
                            height: size.height,
                            pixelsPerSec: pixelsPerSec,
                            lineWidth: 3)
                    }
                    timelineModel.timedNoteDrawables.forEach { timedNoteDrawable in
                        timedNoteDrawable.draw(
                            context: context,
                            height: size.height,
                            pixelsPerSec: pixelsPerSec,
                            lineWidth: 3)
                    }
                    let shouldDrawCurrentTime = timelineDate > timelineModel.startTime.addingTimeInterval(2*60) && timelineDate < timelineModel.startTime.addingTimeInterval(timelineModel.totalWidth) && isShowingCurrentTime
                    if shouldDrawCurrentTime {
                        let currentTimeX = ((timelineDate.timeIntervalSinceReferenceDate - timelineModel.startTime.timeIntervalSinceReferenceDate)*pixelsPerSec) + halfLineWidth
                        var path = Path()
                        path.move(to: CGPoint(x: currentTimeX, y: 0))
                        path.addLine(to: CGPoint(x: currentTimeX, y: size.height))
                        context.stroke(path, with: .foreground, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                }
            }
            .padding(.vertical, spaceToLabels)
            timeLabels
        }.frame(height: height)
    }

    private var timeLabels: some View {
        Canvas { context, size in
            let widthInPixels = size.width - halfLineWidth
            let pixelsPerSec = widthInPixels/timelineModel.totalWidth
            let fullHours = timelineModel.axisDrawable.getFullHours(
                pixelsPerSec: pixelsPerSec,
                widthInPixels: widthInPixels
            )
            fullHours.forEach { fullHour in
                context.draw(
                    Text(fullHour.label).font(.caption),
                    at: CGPoint(x: fullHour.distanceFromStart + halfLineWidth, y: size.height/2),
                    anchor: .center
                )
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}


struct EffectTimeline_Previews: PreviewProvider {

    static var previews: some View {
        List {
            Section {
                EffectTimeline(
                    timelineModel: TimelineModel(
                        everythingForEachLine: everythingForEachLine,
                        everythingForEachRating: everythingForEachRating,
                        everythingForEachTimedNote: everythingForEachTimedNote
                    ),
                    height: 200
                )
            }
        }
    }

    static let everythingForEachRating: [EverythingForOneRating] = [
        EverythingForOneRating(
            time: Date().addingTimeInterval(-2*60*60),
            option: .fourPlus
        ),
        EverythingForOneRating(
            time: Date().addingTimeInterval(-1*60*60),
            option: .plus
        )
    ]

    static let everythingForEachTimedNote: [EverythingForOneTimedNote] = [
        EverythingForOneTimedNote(
            time: Date().addingTimeInterval(-2*60*60),
            color: .blue
        ),
        EverythingForOneTimedNote(
            time: Date().addingTimeInterval(-1*60*60),
            color: .green
        ),
    ]

    static let everythingForEachLine: [EverythingForOneLine] = [
        // full
        EverythingForOneLine(
            substanceName: "a",
            roaDuration: RoaDuration(
                onset: DurationRange(min: 30, max: 60, units: .minutes),
                comeup: DurationRange(min: 30, max: 60, units: .minutes),
                peak: DurationRange(min: 2, max: 3, units: .hours),
                offset: DurationRange(min: 1, max: 2, units: .hours),
                total: nil,
                afterglow: nil
            ),
            onsetDelayInHours: 3,
            startTime: Date().addingTimeInterval(-3*60*60),
            horizontalWeight: 0.5,
            verticalWeight: 0.75,
            color: .blue
        ),
        // total
        EverythingForOneLine(
            substanceName: "b",
            roaDuration: RoaDuration(
                onset: nil,
                comeup: nil,
                peak: nil,
                offset: nil,
                total: DurationRange(min: 4, max: 6, units: .hours),
                afterglow: nil
            ),
            onsetDelayInHours: 3,
            startTime: Date().addingTimeInterval(-2*60*60),
            horizontalWeight: 0.5,
            verticalWeight: 0.5,
            color: .orange
        ),
        // onset comeup
        EverythingForOneLine(
            substanceName: "c",
            roaDuration: RoaDuration(
                onset: DurationRange(min: 20, max: 40, units: .minutes),
                comeup: DurationRange(min: 1, max: 2, units: .hours),
                peak: nil,
                offset: nil,
                total: nil,
                afterglow: nil
            ),
            onsetDelayInHours: 3,
            startTime: Date().addingTimeInterval(-2*60*60),
            horizontalWeight: 0.5,
            verticalWeight: 1,
            color: .pink
        ),
        // onset comeup peak total
        EverythingForOneLine(
            substanceName: "d",
            roaDuration: RoaDuration(
                onset: DurationRange(min: 30, max: 60, units: .minutes),
                comeup: DurationRange(min: 1, max: 2, units: .hours),
                peak: DurationRange(min: 1, max: 2, units: .hours),
                offset: nil,
                total: DurationRange(min: 6, max: 8, units: .hours),
                afterglow: nil
            ),
            onsetDelayInHours: 3,
            startTime: Date().addingTimeInterval(-60*60),
            horizontalWeight: 0.5,
            verticalWeight: 0.5,
            color: .green
        ),
        // onset
        EverythingForOneLine(
            substanceName: "e",
            roaDuration: RoaDuration(
                onset: DurationRange(min: 1, max: 3, units: .hours),
                comeup: nil,
                peak: nil,
                offset: nil,
                total: nil,
                afterglow: nil
            ),
            onsetDelayInHours: 3,
            startTime: Date(),
            horizontalWeight: 0.5,
            verticalWeight: 0.5,
            color: .purple
        ),
        // onset comeup peak
        EverythingForOneLine(
            substanceName: "f",
            roaDuration: RoaDuration(
                onset: DurationRange(min: 30, max: 60, units: .minutes),
                comeup: DurationRange(min: 1, max: 2, units: .hours),
                peak: DurationRange(min: 1, max: 2, units: .hours),
                offset: nil,
                total: nil,
                afterglow: nil
            ),
            onsetDelayInHours: 3,
            startTime: Date().addingTimeInterval(-30*60),
            horizontalWeight: 0.5,
            verticalWeight: 0.75,
            color: .yellow
        ),
        // onset comeup total
        EverythingForOneLine(
            substanceName: "g",
            roaDuration: RoaDuration(
                onset: DurationRange(min: 1, max: 2, units: .hours),
                comeup: DurationRange(min: 1, max: 2, units: .hours),
                peak: nil,
                offset: nil,
                total: DurationRange(min: 6, max: 8, units: .hours),
                afterglow: nil
            ),
            onsetDelayInHours: 3,
            startTime: Date().addingTimeInterval(-45*60),
            horizontalWeight: 0.5,
            verticalWeight: 0.9,
            color: .cyan
        ),
        // onset total
        EverythingForOneLine(
            substanceName: "h",
            roaDuration: RoaDuration(
                onset: DurationRange(min: 1, max: 2, units: .hours),
                comeup: nil,
                peak: nil,
                offset: nil,
                total: DurationRange(min: 6, max: 8, units: .hours),
                afterglow: nil
            ),
            onsetDelayInHours: 1,
            startTime: Date().addingTimeInterval(-60*60),
            horizontalWeight: 0.5,
            verticalWeight: 0.3,
            color: .brown
        ),
        // no timeline
        EverythingForOneLine(
            substanceName: "i",
            roaDuration: nil,
            onsetDelayInHours: 3,
            startTime: Date().addingTimeInterval(-60*60),
            horizontalWeight: 0.5,
            verticalWeight: 0.3,
            color: .brown
        ),
    ]
}
