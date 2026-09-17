import Foundation

/// A user-defined monthly USD budget reconciled against Codex's existing local token-cost ledger.
/// This is an estimate derived from session logs, not an OpenAI account billing balance.
public struct CodexMonthlyBudgetStatus: Sendable, Equatable {
    public let limitUSD: Double
    public let spentUSD: Double
    public let remainingUSD: Double
    public let resetsAt: Date

    public init?(
        limitUSD: Double?,
        tokenSnapshot: CostUsageTokenSnapshot?,
        now: Date = Date(),
        calendar: Calendar = .current)
    {
        guard let limitUSD,
              limitUSD.isFinite,
              limitUSD > 0,
              let tokenSnapshot,
              tokenSnapshot.currencyCode == "USD",
              let month = calendar.dateInterval(of: .month, for: now),
              let finalDay = calendar.date(byAdding: .day, value: -1, to: month.end)
        else { return nil }

        let startKey = Self.dayKey(month.start, calendar: calendar)
        let endKey = Self.dayKey(finalDay, calendar: calendar)
        let costs = tokenSnapshot.daily.compactMap { entry -> Double? in
            guard let key = Self.dayKey(entry.date, calendar: calendar),
                  key >= startKey,
                  key <= endKey,
                  let cost = entry.costUSD,
                  cost.isFinite,
                  cost >= 0
            else { return nil }
            return cost
        }
        let spentUSD = costs.reduce(0, +)
        self.limitUSD = limitUSD
        self.spentUSD = spentUSD
        self.remainingUSD = max(0, limitUSD - spentUSD)
        self.resetsAt = month.end
    }

    private static func dayKey(_ date: Date, calendar: Calendar) -> String {
        CostUsageLocalDay.key(from: date, calendar: calendar)
    }

    private static func dayKey(_ rawDate: String, calendar: Calendar) -> String? {
        let trimmed = rawDate.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count >= 10 {
            let prefix = String(trimmed.prefix(10))
            if prefix.count == 10,
               prefix[prefix.index(prefix.startIndex, offsetBy: 4)] == "-",
               prefix[prefix.index(prefix.startIndex, offsetBy: 7)] == "-"
            {
                return prefix
            }
        }
        return CostUsageDateParser.parse(trimmed).map { self.dayKey($0, calendar: calendar) }
    }
}
