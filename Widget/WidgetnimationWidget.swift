//
//  WidgetnimationWidget.swift
//  WidgetnimationWidget
//
//  Created by 길지훈 on 2026-02-24.
//

import SwiftUI
import UIKit
import WidgetKit

/**
 Arc Mask + clockHandRotationEffect 기반 위젯 애니메이션.

 기존 BlinkMask 폰트 방식을 대체:
 - 커스텀 폰트 불필요 (BlinkMask.otf 제거)
 - 투명 배경 지원 (잔상 없음)
 - 코드 대폭 단순화

 원리:
 1) 모든 프레임을 ZStack에 쌓고 각각 ArcShape로 마스킹
 2) clockHandRotationEffect가 마스크를 회전시켜 프레임 순차 표시
 3) 한 시점에 정확히 1개 프레임만 뷰포트에 존재
 */
struct WidgetnimationWidgetView: View {
    var entry: WidgetnimationEntry

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            if let frames = entry.customFrames {
                AnimatedFrameView(
                    frames: frames,
                    size: size,
                    cycleDuration: 2.0
                )
                .frame(width: geo.size.width, height: geo.size.height)
            } else {
                placeholderView
            }
        }
    }

    private var placeholderView: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.badge.plus")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("Select an image\nin the app")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WidgetnimationProvider: TimelineProvider {

    func placeholder(in context: Context) -> WidgetnimationEntry {
        WidgetnimationEntry(date: .now, customFrames: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetnimationEntry) -> Void) {
        completion(WidgetnimationEntry(date: .now, customFrames: loadCustomFrames()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetnimationEntry>) -> Void) {
        let entry = WidgetnimationEntry(date: .now, customFrames: loadCustomFrames())

        // .never — 앱에서 reloadAllTimelines() 호출 시에만 업데이트
        completion(Timeline(entries: [entry], policy: .never))
    }

    private func loadCustomFrames() -> [UIImage]? {
        let frames = (0..<FrameStorage.frameCount).compactMap { i in
            FrameStorage.loadFrameImage(index: i)
        }
        guard frames.count == FrameStorage.frameCount else { return nil }
        return frames
    }
}

struct WidgetnimationEntry: TimelineEntry {
    let date: Date
    let customFrames: [UIImage]?
}

struct WidgetnimationWidget: Widget {
    let kind = "WidgetnimationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetnimationProvider()) { entry in
            WidgetnimationWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Widgetnimation")
        .description("Animated widget with your image")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct WidgetnimationWidgetBundle: WidgetBundle {
    var body: some Widget {
        WidgetnimationWidget()
    }
}
