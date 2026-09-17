import Foundation

extension ProviderConfig {
    public var codexMonthlyBudgetUSD: String? {
        get { self.extensionValue(forKey: "codexMonthlyBudgetUSD") }
        set { self.setExtensionValue(newValue, forKey: "codexMonthlyBudgetUSD") }
    }

    public var sanitizedCodexMonthlyBudgetUSD: Double? {
        guard let rawValue = self.codexMonthlyBudgetUSD?.trimmingCharacters(in: .whitespacesAndNewlines),
              let value = Double(rawValue),
              value.isFinite,
              value > 0
        else { return nil }
        return value
    }

    public var codexActiveSource: CodexActiveSource? {
        get { self.extensionValue(forKey: "codexActiveSource") }
        set { self.setExtensionValue(newValue, forKey: "codexActiveSource") }
    }

    public var codexProfileHomePaths: [String]? {
        get { self.extensionValue(forKey: "codexProfileHomePaths") }
        set { self.setExtensionValue(newValue, forKey: "codexProfileHomePaths") }
    }
}
