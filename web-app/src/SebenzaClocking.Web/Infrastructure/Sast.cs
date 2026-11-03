namespace SebenzaClocking.Web.Infrastructure;

/// <summary>All stored timestamps are UTC; UAS operates in Africa/Johannesburg (SAST, UTC+2, no DST).</summary>
public static class Sast
{
    public static System.DateTime FromUtc(System.DateTime utc)
        => System.DateTime.SpecifyKind(utc, System.DateTimeKind.Utc).AddHours(2);
    public static System.DateTime Today => System.DateTime.UtcNow.AddHours(2).Date;

    public static string HHmm(System.DateTime utc) => FromUtc(utc).ToString("HH:mm");
    public static string Date(System.DateTime utc) => FromUtc(utc).ToString("dd MMM yyyy");
    public static string DateTime(System.DateTime utc) => FromUtc(utc).ToString("dd MMM yyyy HH:mm");
}
