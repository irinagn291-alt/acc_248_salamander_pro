import SwiftUI
import UIKit

/// Role: Pass. Pass-locked chrome. The open ticket never leaves. Search, Cookbook, and Settings arrive as sheets. Cook is not a pushed scene.
struct PassRoot: View {
    @Environment(PassDesk.self) private var desk
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var desk = desk
        Group {
            if let bootFault = desk.bootFault, !desk.isReady {
                PassVacant(
                    art: "slm_EmptyHome",
                    headline: "The pass did not open.",
                    line: bootFault,
                    verb: "Try again",
                    action: { Task { await desk.retryBoot() } }
                )
            } else if !desk.isReady {
                splash
            } else if desk.showOnboarding {
                OnboardingView()
            } else {
                HomeView()
                    .sheet(item: $desk.sheet) { sheet in
                        sheetBody(sheet)
                            .presentationDragIndicator(.visible)
                            .presentationBackground(PassInk.surface)
                            .presentationCornerRadius(PassRadius.card)
                    }
                    .sheet(isPresented: $desk.fireRuleOpen) {
                        FireRuleView()
                            .presentationDragIndicator(.visible)
                            .presentationBackground(PassInk.surface)
                            .presentationCornerRadius(PassRadius.card)
                    }
                    .overlay {
                        if desk.commitFlash {
                            Image("slm_SuccessMark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: PassSpace.step(12), height: PassSpace.step(12))
                                .accessibilityHidden(true)
                                .allowsHitTesting(false)
                        }
                    }
                    .animation(PassMotion.crossfade(reduceMotion), value: desk.commitFlash)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PassInk.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .tint(PassInk.accent)
        .animation(PassMotion.crossfade(reduceMotion), value: desk.isReady)
        .animation(PassMotion.crossfade(reduceMotion), value: desk.showOnboarding)
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            desk.tickDay()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            desk.tickDay()
        }
    }

    private var splash: some View {
        ZStack {
            PassInk.background
            Image("slm_Splash")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func sheetBody(_ sheet: PassSheet) -> some View {
        switch sheet {
        case .search:
            SearchView()
        case .cookbook:
            CookbookView()
        case .settings:
            SettingsView()
        }
    }
}
