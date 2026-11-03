using System.Text;

namespace SebenzaClocking.Core;

/// <summary>Minimal RFC-4180 CSV writer (no external dependencies).</summary>
public static class CsvWriter
{
    public static string Write(IEnumerable<string> header, IEnumerable<IEnumerable<object?>> rows)
    {
        var sb = new StringBuilder();
        sb.AppendLine(string.Join(",", header.Select(Escape)));
        foreach (var row in rows)
            sb.AppendLine(string.Join(",", row.Select(v => Escape(v?.ToString()))));
        return sb.ToString();
    }

    private static string Escape(string? value)
    {
        if (value is null) return string.Empty;
        var needsQuotes = value.Contains(',') || value.Contains('"')
                       || value.Contains('\n') || value.Contains('\r');
        var escaped = value.Replace("\"", "\"\"");
        return needsQuotes ? $"\"{escaped}\"" : escaped;
    }
}
