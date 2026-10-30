// Zusammenhang: Backup/BackupService.swift, Shell/AppSheets.swift, Pages/SettingsPage.swift, App/AppModel.swift (reload)
import ParalistCore
import SwiftUI

struct BackupImportSheet: View {
    let url: URL
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var state: Phase = .checking

    enum Phase {
        case checking, invalid, failed, running
        case ready(ImportPlan)
        case done(ImportResult)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer(minLength: 0)
                content
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .navigationTitle(L.s("data_import"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if case .running = state {} else {
                        Button { close() } label: { Image(systemName: AppIcons.close) }.accessibilityLabel(L.s("dialog_cancel"))
                    }
                }
            }
        }
        .task { await check() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .checking:
            busy(L.s("import_checking"))
        case .running:
            busy(L.s("import_running"))
        case .invalid:
            message(L.s("import_invalid"))
        case .failed:
            message(L.s("import_failed"))
        case .ready(let plan):
            summary(plan)
        case .done(let result):
            VStack(spacing: 20) {
                Image(systemName: AppIcons.task.filled).font(.system(size: 44)).foregroundStyle(Palette.done)
                Text(L.s("import_done")).font(Typo.titleLarge)
                Text(L.f("import_done_text", result.written)).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant).multilineTextAlignment(.center)
                Button(L.s("import_open_app")) { dismiss() }.buttonStyle(.glassProminent).controlSize(.large)
            }
        }
    }

    private func busy(_ text: String) -> some View {
        VStack(spacing: 16) {
            ProgressView().controlSize(.large)
            Text(text).font(Typo.bodyLarge).foregroundStyle(Palette.onSurfaceVariant)
        }
    }

    private func message(_ text: String) -> some View {
        VStack(spacing: 20) {
            Text(text).font(Typo.bodyLarge).multilineTextAlignment(.center)
            Button(L.s("dialog_ok")) { dismiss() }.buttonStyle(.glass)
        }
    }

    private func summary(_ plan: ImportPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.f("import_summary", plan.entriesTotal, plan.imagesTotal, plan.attachmentsPresent)).font(Typo.titleLarge)
            let others = plan.attachmentsTotal - plan.imagesTotal
            if others > 0 { Text(L.f("import_attachments_other", others)).font(Typo.bodyMedium).foregroundStyle(Palette.onSurfaceVariant) }
            Text(L.f("import_details", plan.newEntries, plan.updatedEntries, plan.unchangedEntries)).font(Typo.bodyMedium)
            if !plan.broken.isEmpty { Text(L.f("import_broken", plan.broken.count)).font(Typo.bodyMedium).foregroundStyle(Palette.error) }
            if plan.attachmentsRejected > 0 { Text(L.f("import_rejected_files", plan.attachmentsRejected)).font(Typo.bodyMedium).foregroundStyle(Palette.error) }
            if !plan.hasChanges { Text(L.s("import_nothing")).font(Typo.bodyMedium).foregroundStyle(Palette.muted) }
            HStack {
                Spacer()
                Button(L.s("dialog_cancel")) { close() }.buttonStyle(.glass)
                Button(L.s("import_confirm")) { Task { await run(plan) } }
                    .buttonStyle(.glassProminent)
                    .disabled(!plan.hasChanges)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(Palette.surfaceContainer, in: RoundedRectangle(cornerRadius: Dimens.cardRadius))
    }

    private func check() async {
        do {
            state = .ready(try await BackupService.prepare(url, model.library))
        } catch {
            state = .invalid
        }
    }

    private func run(_ plan: ImportPlan) async {
        state = .running
        do {
            let result = try await BackupService.apply(plan, model.library)
            _ = model.rebuildIndex()
            state = .done(result)
        } catch {
            state = .failed
        }
    }

    private func close() {
        if case .ready(let plan) = state { BackupService.discard(plan) }
        dismiss()
    }
}
