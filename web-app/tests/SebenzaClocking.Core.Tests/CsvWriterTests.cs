using SebenzaClocking.Core;
using Xunit;

namespace SebenzaClocking.Core.Tests;

public class CsvWriterTests
{
    [Fact]
    public void EscapesCommasAndQuotes()
    {
        var csv = CsvWriter.Write(
            new[] { "Name", "Note" },
            new[] { new object?[] { "Dlamini, N", "said \"hi\"" } });
        Assert.Contains("Name,Note", csv);
        Assert.Contains("\"Dlamini, N\"", csv);
        Assert.Contains("\"said \"\"hi\"\"\"", csv);
    }

    [Fact]
    public void NullBecomesEmptyField()
    {
        var csv = CsvWriter.Write(new[] { "A" }, new[] { new object?[] { null } });
        var lines = csv.Split('\n');
        Assert.Equal(string.Empty, lines[1].TrimEnd('\r'));
    }
}
