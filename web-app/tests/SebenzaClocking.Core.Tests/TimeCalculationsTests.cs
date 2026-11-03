using SebenzaClocking.Core;
using Xunit;

namespace SebenzaClocking.Core.Tests;

public class TimeCalculationsTests
{
    [Fact]
    public void WorkedHours_DeductsBreak()
    {
        var clockIn  = new DateTime(2026, 9, 20, 6, 0, 0, DateTimeKind.Utc);
        var clockOut = new DateTime(2026, 9, 20, 18, 0, 0, DateTimeKind.Utc);
        Assert.Equal(11.5m, TimeCalculations.WorkedHours(clockIn, clockOut, 30));
    }

    [Fact]
    public void WorkedHours_RejectsNegativeSpan()
    {
        var clockIn  = new DateTime(2026, 9, 20, 18, 0, 0, DateTimeKind.Utc);
        var clockOut = new DateTime(2026, 9, 20, 6, 0, 0, DateTimeKind.Utc);
        Assert.Equal(0m, TimeCalculations.WorkedHours(clockIn, clockOut, 0));
    }

    [Theory]
    [InlineData(8.4, "8h 24m")]
    [InlineData(12.0, "12h 00m")]
    [InlineData(0.75, "0h 45m")]
    [InlineData(-2, "0h 00m")]
    public void FormatHours(decimal hours, string expected)
        => Assert.Equal(expected, TimeCalculations.FormatHours(hours));

    [Fact]
    public void IsLateSast_UsesGraceAgainst0600()
    {
        // 06:00 SAST = 04:00 UTC
        var onTime    = new DateTime(2026, 9, 21, 4, 5, 0, DateTimeKind.Utc);
        var late      = new DateTime(2026, 9, 21, 4, 6, 0, DateTimeKind.Utc);
        var veryLate  = new DateTime(2026, 9, 21, 7, 15, 0, DateTimeKind.Utc);
        Assert.False(TimeCalculations.IsLateSast(onTime));
        Assert.True(TimeCalculations.IsLateSast(late));
        Assert.True(TimeCalculations.IsLateSast(veryLate));
    }
}
