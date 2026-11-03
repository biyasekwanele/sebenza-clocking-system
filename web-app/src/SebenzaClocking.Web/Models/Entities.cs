using System.Text.Json.Serialization;

namespace SebenzaClocking.Web.Models;

// POCOs mapped to the approved Phase 2 schema (snake_case columns). All data
// access is performed with the signed-in user's JWT, so RLS policies apply.

public class Department
{
    [JsonPropertyName("id")] public Guid Id { get; set; }
    [JsonPropertyName("name")] public string Name { get; set; } = string.Empty;
}

public class Employee
{
    [JsonPropertyName("id")] public Guid Id { get; set; }
    [JsonPropertyName("user_id")] public Guid UserId { get; set; }
    [JsonPropertyName("employee_code")] public string EmployeeCode { get; set; } = string.Empty;
    [JsonPropertyName("full_name")] public string FullName { get; set; } = string.Empty;
    [JsonPropertyName("email")] public string Email { get; set; } = string.Empty;
    [JsonPropertyName("department_id")] public Guid? DepartmentId { get; set; }
    [JsonPropertyName("role")] public string Role { get; set; } = "employee";
    [JsonPropertyName("is_active")] public bool IsActive { get; set; } = true;
    [JsonPropertyName("departments")] public Department? Dept { get; set; }

    public string DepartmentName => Dept?.Name ?? "—";
    public bool ClockedInToday { get; set; }
    public bool OnBreak { get; set; }
}

public class AttendanceRecord
{
    [JsonPropertyName("id")] public Guid Id { get; set; }
    [JsonPropertyName("employee_id")] public Guid EmployeeId { get; set; }
    [JsonPropertyName("clock_in")] public DateTime ClockIn { get; set; }
    [JsonPropertyName("clock_out")] public DateTime? ClockOut { get; set; }
    [JsonPropertyName("break_minutes")] public int BreakMinutes { get; set; }
    [JsonPropertyName("total_hours")] public decimal? TotalHours { get; set; }
    [JsonPropertyName("overtime_hours")] public decimal OvertimeHours { get; set; }
    [JsonPropertyName("status")] public string Status { get; set; } = "Open";
    [JsonPropertyName("employees")] public Employee? Emp { get; set; }

    public string EmployeeName => Emp?.FullName ?? "—";
    public string EmployeeCode => Emp?.EmployeeCode ?? "—";
    public string DepartmentName => Emp?.DepartmentName ?? "—";
    public bool IsLate => Core.TimeCalculations.IsLateSast(ClockIn);
}

public class OvertimeRequest
{
    [JsonPropertyName("id")] public Guid Id { get; set; }
    [JsonPropertyName("employee_id")] public Guid EmployeeId { get; set; }
    [JsonPropertyName("attendance_id")] public Guid AttendanceId { get; set; }
    [JsonPropertyName("work_date")] public DateTime WorkDate { get; set; }
    [JsonPropertyName("hours")] public decimal Hours { get; set; }
    [JsonPropertyName("reason")] public string Reason { get; set; } = string.Empty;
    [JsonPropertyName("status")] public string Status { get; set; } = "Pending";
    [JsonPropertyName("reviewed_by")] public Guid? ReviewedBy { get; set; }
    [JsonPropertyName("reviewed_at")] public DateTime? ReviewedAt { get; set; }
    [JsonPropertyName("employees")] public Employee? Emp { get; set; }

    public string EmployeeName => Emp?.FullName ?? "—";
    public string DepartmentName => Emp?.DepartmentName ?? "—";
}

public class AttendanceCorrection
{
    [JsonPropertyName("id")] public Guid Id { get; set; }
    [JsonPropertyName("attendance_id")] public Guid AttendanceId { get; set; }
    [JsonPropertyName("employee_id")] public Guid EmployeeId { get; set; }
    [JsonPropertyName("field")] public string Field { get; set; } = string.Empty;
    [JsonPropertyName("old_value")] public string? OldValue { get; set; }
    [JsonPropertyName("new_value")] public string NewValue { get; set; } = string.Empty;
    [JsonPropertyName("reason")] public string Reason { get; set; } = string.Empty;
    [JsonPropertyName("status")] public string Status { get; set; } = "Pending";
    [JsonPropertyName("reviewed_by")] public Guid? ReviewedBy { get; set; }
    [JsonPropertyName("reviewed_at")] public DateTime? ReviewedAt { get; set; }
    [JsonPropertyName("created_at")] public DateTime CreatedAt { get; set; }
    [JsonPropertyName("employees")] public Employee? Emp { get; set; }

    public string EmployeeName => Emp?.FullName ?? "—";
}

public class AuditLogEntry
{
    [JsonPropertyName("id")] public Guid Id { get; set; }
    [JsonPropertyName("actor_id")] public Guid? ActorId { get; set; }
    [JsonPropertyName("entity")] public string Entity { get; set; } = string.Empty;
    [JsonPropertyName("entity_id")] public Guid? EntityId { get; set; }
    [JsonPropertyName("action")] public string Action { get; set; } = string.Empty;
    [JsonPropertyName("details")] public System.Text.Json.JsonElement? Details { get; set; }
    [JsonPropertyName("created_at")] public DateTime CreatedAt { get; set; }
    [JsonPropertyName("employees")] public Employee? Actor { get; set; }

    public string ActorName => Actor?.FullName ?? "system";
}
