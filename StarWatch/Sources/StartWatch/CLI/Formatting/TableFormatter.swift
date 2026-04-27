// StartWatch — TableFormatter: форматирование таблиц для CLI
import Foundation

enum TableFormatter {
    static func format(rows: [[String]], headers: [String]? = nil) -> String {
        var allRows = rows
        if let headers = headers {
            allRows.insert(headers, at: 0)
        }

        guard let first = allRows.first else { return "" }
        var colWidths = Array(repeating: 0, count: first.count)

        for row in allRows {
            for (i, cell) in row.enumerated() where i < colWidths.count {
                colWidths[i] = max(colWidths[i], cell.count)
            }
        }

        var lines: [String] = []

        if let headers = headers {
            let headerLine = zip(headers, colWidths)
                .map { $0.padding(toLength: $1, withPad: " ", startingAt: 0) }
                .joined(separator: "  ")
            lines.append(headerLine)
            let separator = colWidths.map { String(repeating: "─", count: $0) }.joined(separator: "  ")
            lines.append(separator)
            for row in rows {
                let line = zip(row, colWidths)
                    .map { $0.padding(toLength: $1, withPad: " ", startingAt: 0) }
                    .joined(separator: "  ")
                lines.append(line)
            }
        } else {
            for row in rows {
                let line = zip(row, colWidths)
                    .map { $0.padding(toLength: $1, withPad: " ", startingAt: 0) }
                    .joined(separator: "  ")
                lines.append(line)
            }
        }

        return lines.joined(separator: "\n")
    }
}
