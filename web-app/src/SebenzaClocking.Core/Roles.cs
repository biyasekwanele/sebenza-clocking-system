namespace SebenzaClocking.Core;

public static class Roles
{
    public const string Employee   = "employee";
    public const string Supervisor = "supervisor";
    public const string Admin      = "admin";

    public static bool IsManager(string? role) =>
        string.Equals(role, Supervisor, StringComparison.OrdinalIgnoreCase) ||
        string.Equals(role, Admin, StringComparison.OrdinalIgnoreCase);
}
