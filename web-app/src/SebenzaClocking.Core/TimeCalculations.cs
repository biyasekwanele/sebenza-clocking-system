namespace SebenzaClocking.Core;

/// <summary>
/// Pure working-hour / overtime / lateness calculations used by reports,
/// dashboards and validation. Authoritative values are computed by the
/// database (generated total_hours column, apply_decision trigger).
/// </summary>
public static class TimeCalculations
{
    /// <summary>Worked hours = clock-out − clock-in − approved break time.</summary>
    public static decimal WorkedHours(DateTime clockIn, DateTime clockOut, int breakMinutes)
    {
        if (clockOut <= clockIn) return 0m;
        var net = clockOut - clockIn - TimeSpan.FromMinutes(Math.Max(0, breakMinutes));
        return Math.Max(0m, Math.Round((decimal)net.TotalHours, 2, MidpointRounding.AwayFromZero));
    }

    /// <summary>"8h 24m" style display used across web and reports.</summary>
    public static string FormatHours(decimal hours)
    {
        if (hours < 0) hours = 0;
        var totalMinutes = (int)Math.Round(hours * 60m, MidpointRounding.AwayFromZero);
        return $"{totalMinutes / 60}h {totalMinutes % 60:00}m";
    }

    /// <summary>
    /// Late arrival vs the organisation's standard 06:00 SAST start (the approved
    /// schema has no per-employee shift table; 06:00–18:00 is the shift shown in
    /// the SRS interface designs). Five-minute grace period.
    /// </summary>
    public static bool IsLateSast(DateTime clockInUtc, int graceMinutes = 5)
    {
        var sast = clockInUtc.AddHours(2); // SAST = UTC+2, no DST
        var start = sast.Date.AddHours(6);
        return sast > start.AddMinutes(graceMinutes);
    }
}
