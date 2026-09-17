import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

struct CodexMonthlyBudgetTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test
    func `monthly budget counts only the current calendar month`() throws {
        let now = try #require(ISO8601DateFormatter().date(from: "2026-09-17T12:00:00Z"))
        let status = try #require(CodexMonthlyBudgetStatus(
            limitUSD: 100,
            tokenSnapshot: self.snapshot(now: now),
            now: now,
            calendar: self.calendar))

        #expect(status.limitUSD == 100)
        #expect(status.spentUSD == 25)
        #expect(status.remainingUSD == 75)
        #expect(self.calendar.component(.month, from: status.resetsAt) == 10)
    }

    @Test
    func `monthly budget rejects missing invalid or non USD inputs`() throws {
        let now = try #require(ISO8601DateFormatter().date(from: "2026-09-17T12:00:00Z"))
        #expect(CodexMonthlyBudgetStatus(
            limitUSD: 0,
            tokenSnapshot: self.snapshot(now: now),
            now: now,
            calendar: self.calendar) == nil)
        #expect(CodexMonthlyBudgetStatus(
            limitUSD: 100,
            tokenSnapshot: nil,
            now: now,
            calendar: self.calendar) == nil)
        #expect(CodexMonthlyBudgetStatus(
            limitUSD: 100,
            tokenSnapshot: self.snapshot(now: now, currencyCode: "EUR"),
            now: now,
            calendar: self.calendar) == nil)
    }

    @Test
    func `Codex config sanitizes the monthly budget`() {
        var config = ProviderConfig(id: .codex)
        config.codexMonthlyBudgetUSD = " 125.50 "
        #expect(config.sanitizedCodexMonthlyBudgetUSD == 125.5)
        config.codexMonthlyBudgetUSD = "not-money"
        #expect(config.sanitizedCodexMonthlyBudgetUSD == nil)
    }

    @Test
    func `Codex cost card shows monthly spend and remaining balance`() throws {
        let now = try #require(ISO8601DateFormatter().date(from: "2026-09-17T12:00:00Z"))
        let metadata = try #require(ProviderDefaults.metadata[.codex])
        let model = UsageMenuCardView.Model.make(.init(
            provider: .codex,
            metadata: metadata,
            snapshot: nil,
            credits: nil,
            creditsError: nil,
            dashboardError: nil,
            tokenSnapshot: self.snapshot(now: now),
            tokenError: nil,
            account: AccountInfo(email: nil, plan: nil),
            isRefreshing: false,
            lastError: nil,
            usageBarsShowUsed: true,
            resetTimeDisplayStyle: .countdown,
            tokenCostUsageEnabled: true,
            codexMonthlyBudgetUSD: 100,
            showOptionalCreditsAndExtraUsage: true,
            hidePersonalInfo: false,
            costUsageBucketCalendar: self.calendar,
            now: now))

        #expect(model.tokenUsage?.monthlyBudgetLine == "This month: $25.00 / $100.00")
        #expect(model.tokenUsage?.monthlyBalanceLine == "Remaining balance: $75.00")
    }

    private func snapshot(now: Date, currencyCode: String = "USD") -> CostUsageTokenSnapshot {
        CostUsageTokenSnapshot(
            sessionTokens: 100,
            sessionCostUSD: 15,
            last30DaysTokens: 300,
            last30DaysCostUSD: 75,
            currencyCode: currencyCode,
            daily: [
                self.entry(date: "2026-08-31", cost: 50),
                self.entry(date: "2026-09-01", cost: 10),
                self.entry(date: "2026-09-17", cost: 15),
                self.entry(date: "2026-10-01", cost: 80),
            ],
            updatedAt: now)
    }

    private func entry(date: String, cost: Double) -> CostUsageDailyReport.Entry {
        .init(
            date: date,
            inputTokens: 10,
            outputTokens: 5,
            totalTokens: 15,
            costUSD: cost,
            modelsUsed: ["gpt-5"],
            modelBreakdowns: nil)
    }
}
