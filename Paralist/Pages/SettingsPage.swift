// Zusammenhang: App/AppPrefs.swift, Pages/SettingsNavigation.swift (Navigation, SettingsHeader, ScrollGlow), ParalistCore Planning/DayPeriods.swift, Reminders/ReminderScheduler.swift, Pages/TrashPage.swift, Shell/Router.swift
import ParalistCore
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SettingsPage: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var phase
    @State private var notificationsOn = false
    @State private var licenses = false
    @State private var exporting = false
    @State private var limitOpen = false
    @State private var importing = false
    @State private var shared: BackupFile?
    @State private var spotted = false
    @State private var floor: CGFloat = .infinity

    var body: some View {
        @Bindable var prefs = model.prefs
        Form {
            group("settings_appearance") {
                Picker(selection: $prefs.themeMode) {
                    Text(L.s("settings_theme_system")).tag(ThemeMode.system)
                    Text(L.s("settings_theme_light")).tag(ThemeMode.light)
                    Text(L.s("settings_theme_dark")).tag(ThemeMode.dark)
                } label: { Label(L.s("settings_theme"), systemImage: AppIcons.palette) }
                Picker(selection: $prefs.language) {
                    ForEach(AppLanguage.allCases) { Text($0.nativeName).tag($0) }
                } label: { Label(L.s("menu_language"), systemImage: AppIcons.language) }
            }
            SettingsNavigation(spotted: $spotted, floor: floor)
            group("settings_notifications") {
                Button { openSettings() } label: {
                    LabeledContent {
                        Image(systemName: AppIcons.openExternal)
                    } label: {
                        Label { VStack(alignment: .leading, spacing: 4) {
                            Text(L.s("settings_notif_system"))
                            Text(L.s(notificationsOn ? "settings_notif_on" : "settings_notif_off")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
                        } } icon: { Image(systemName: AppIcons.bell.outlined) }
                    }
                }
                Toggle(isOn: $prefs.lockScreenDetails) {
                    Label { VStack(alignment: .leading, spacing: 4) {
                        Text(L.s("settings_lock_screen"))
                        Text(L.s("settings_lock_screen_hint")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
                    } } icon: { Image(systemName: AppIcons.lock) }
                }
            }
            group("briefing_schedule") {
                Picker(L.s("briefing_schedule"), selection: $prefs.briefingSchedule) {
                    Text(L.s("briefing_off")).tag(BriefingSchedule.off)
                    Text(L.s("briefing_sunday")).tag(BriefingSchedule.sunday)
                    Text(L.s("briefing_monday")).tag(BriefingSchedule.monday)
                }
                .pickerStyle(.inline)
                .labelsHidden()
                if prefs.briefingSchedule != .off {
                    DatePicker(selection: Binding(get: {
                        model.today.at(hour: prefs.briefingHour, minute: prefs.briefingMinute, in: .current)
                    }, set: { date in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                        prefs.briefingHour = c.hour ?? 8
                        prefs.briefingMinute = c.minute ?? 0
                    }), displayedComponents: .hourAndMinute) {
                        Label(L.s("briefing_time"), systemImage: AppIcons.schedule)
                    }
                }
            }
            group("settings_periods") {
                ForEach(DayPeriod.allCases, id: \.self) { period in
                    DatePicker(selection: Binding(get: {
                        model.today.at(hour: prefs.periods[period] / 60, minute: prefs.periods[period] % 60, in: .current)
                    }, set: { date in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                        prefs.periods[period] = (c.hour ?? 0) * 60 + (c.minute ?? 0)
                    }), displayedComponents: .hourAndMinute) {
                        Label(L.s("period_\(period.key)"), systemImage: AppIcons.schedule)
                    }
                }
                Text(L.s("settings_periods_hint")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
            }
            group("nav_overview") { OverviewTabOptions(limitOpen: $limitOpen) }
            group("settings_pins") {
                LabeledContent {
                    Text("\(prefs.pinLimit)").font(Typo.titleMedium).foregroundStyle(Palette.primary)
                } label: { Label(L.s("settings_pin_limit"), systemImage: AppIcons.pin.outlined) }
                Slider(value: Binding(get: { Double(prefs.pinLimit) }, set: { prefs.pinLimit = PinLimit.clamp(Int($0)) }),
                       in: Double(PinLimit.range.lowerBound)...Double(PinLimit.range.upperBound), step: 1)
                Text(L.s("settings_pin_limit_hint")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
            }
            group("settings_learning") {
                LabeledContent {
                    Text("\(prefs.newCardsPerDay)").font(Typo.titleMedium).foregroundStyle(Palette.primary)
                } label: { Label(L.s("fc_new_cards_per_day"), systemImage: AppIcons.school) }
                Slider(value: Binding(get: { Double(prefs.newCardsPerDay) }, set: { prefs.newCardsPerDay = Int($0) }), in: 0...200, step: 5)
                Text(L.s("settings_learning_hint")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
            }
            group("settings_data") {
                Button { Task { await export() } } label: {
                    Label { VStack(alignment: .leading, spacing: 4) {
                        Text(L.s("data_export"))
                        Text(L.s(exporting ? "data_exporting" : "data_export_hint")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
                    } } icon: { Image(systemName: AppIcons.download) }
                }
                .disabled(exporting)
                Button { importing = true } label: {
                    Label { VStack(alignment: .leading, spacing: 4) {
                        Text(L.s("data_import"))
                        Text(L.s("settings_import_hint")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
                    } } icon: { Image(systemName: AppIcons.upload) }
                }
                NavigationLink(value: Route.trash) {
                    Label { VStack(alignment: .leading, spacing: 4) {
                        Text(L.s("trash_title"))
                        Text(L.s("settings_trash_hint")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
                    } } icon: { Image(systemName: AppIcons.delete) }
                }
                Button {
                    model.say(L.f("settings_rebuild_done", model.rebuildIndex()))
                } label: {
                    Label { VStack(alignment: .leading, spacing: 4) {
                        Text(L.s("settings_rebuild_index"))
                        Text(L.s("settings_rebuild_hint")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
                    } } icon: { Image(systemName: AppIcons.refresh) }
                }
            }
            group("page_feedback") {
                NavigationLink(value: Route.feedback) {
                    Label { VStack(alignment: .leading, spacing: 4) {
                        Text(L.s("page_feedback"))
                        Text(L.s("settings_feedback_hint")).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
                    } } icon: { Image(systemName: AppIcons.feedback) }
                }
            }
            group("settings_about") {
                Button { licenses = true } label: { Label(L.s("settings_licenses"), systemImage: AppIcons.document.outlined) }
                VStack(alignment: .leading, spacing: 4) {
                    Text(L.s("settings_local_note")).font(Typo.bodyMedium)
                    Text(L.f("settings_version", Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")).font(Typo.bodySmall).foregroundStyle(Palette.muted)
                }
            }
        }
        .tint(Palette.primary)
        .foregroundStyle(Palette.onSurface)
        .environment(\.defaultMinListRowHeight, 64)
        .listSectionSpacing(.custom(20))
        .paneTitle("page_settings")
        .navigationDestination(isPresented: $limitOpen) { OverviewLimitPage() }
        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).maxY } action: { floor = $0 }
        .overlay { if !prefs.navHintSeen && !spotted { ScrollGlow().transition(.opacity) } }
        .animation(Motion.bars, value: spotted)
        .onDisappear { if spotted { prefs.navHintSeen = true } }
        .alert(L.s("settings_licenses"), isPresented: $licenses) {
            Button(L.s("create_close"), role: .cancel) {}
        } message: { Text(L.s("settings_licenses_list")) }
        .fileImporter(isPresented: $importing, allowedContentTypes: [UTType(exportedAs: "app.paralist.backup"), .zip]) { result in
            if case .success(let url) = result { router.backup = BackupFile(url: url) }
        }
        .sheet(item: $shared) { file in ShareSheet(items: [file.url]).presentationDetents([.medium, .large]) }
        .task(id: phase) { notificationsOn = await model.reminders.isAuthorized() }
        .onChange(of: prefs.briefingSchedule) { old, new in
            if new == .monday && old != .monday { prefs.briefingHour = 8 }
            if new == .sunday && old != .sunday { prefs.briefingHour = 18 }
            rescheduleBriefing()
        }
        .onChange(of: prefs.lockScreenDetails) { _, on in model.reminders.lockScreenDetails = on }
        .onChange(of: prefs.briefingHour) { rescheduleBriefing() }
        .onChange(of: prefs.briefingMinute) { rescheduleBriefing() }
    }

    private func group<Content: View>(_ key: String, @ViewBuilder _ content: () -> Content) -> some View {
        Section {
            content()
        } header: {
            SettingsHeader(key: key)
        }
    }

    private func export() async {
        exporting = true
        defer { exporting = false }
        do {
            let (url, stats) = try await BackupService.export(model.library)
            model.say(L.f("data_export_done", stats.entries, stats.attachments))
            shared = BackupFile(url: url)
        } catch {
            model.say(L.s("export_failed"))
        }
    }

    private func rescheduleBriefing() {
        model.reminders.scheduleBriefing(model.prefs, briefing: model.weekBriefing(for: WeekBriefingBuilder.weekFor(model.today)))
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
    }
}
