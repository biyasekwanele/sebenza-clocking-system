using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace SebenzaClocking.Web.Models;

public class LoginViewModel
{
    [Required, EmailAddress] public string Email { get; set; } = string.Empty;
    [Required, DataType(DataType.Password)] public string Password { get; set; } = string.Empty;
    public bool RememberMe { get; set; }
}

public class DashboardViewModel
{
    public int Present { get; set; }
    public int Late { get; set; }
    public int Completed { get; set; }
    public int Absent { get; set; }
    public int PendingOvertime { get; set; }
    public IReadOnlyList<AttendanceRecord> Activity { get; set; } = Array.Empty<AttendanceRecord>();
    public IReadOnlyList<OvertimeRequest> RecentOvertime { get; set; } = Array.Empty<OvertimeRequest>();
    public int[] Trend { get; set; } = Array.Empty<int>();
    public string[] TrendLabels { get; set; } = Array.Empty<string>();
}

public class AttendanceListViewModel
{
    public DateOnly Date { get; set; }
    public Guid? DepartmentId { get; set; }
    public IReadOnlyList<AttendanceRecord> Records { get; set; } = Array.Empty<AttendanceRecord>();
    public List<SelectListItem> Departments { get; set; } = new();
}

public class EmployeeIndexViewModel
{
    public string? Search { get; set; }
    public IReadOnlyList<Employee> Employees { get; set; } = Array.Empty<Employee>();
}

public class EmployeeFormViewModel
{
    public Guid? Id { get; set; }
    [Required] public string EmployeeCode { get; set; } = string.Empty;
    [Required] public string FullName { get; set; } = string.Empty;
    [Required, EmailAddress] public string Email { get; set; } = string.Empty;
    [Required] public string Role { get; set; } = "employee";
    public Guid? DepartmentId { get; set; }
    public bool IsActive { get; set; } = true;
    [MinLength(6, ErrorMessage = "Password must be at least 6 characters.")]
    public string? Password { get; set; }   // temporary password for the new account
    public List<SelectListItem> Departments { get; set; } = new();
    public List<SelectListItem> Roles { get; } = new()
    { new("Employee", "employee"), new("Supervisor", "supervisor"), new("Administrator", "admin") };
}

public class CorrectionsViewModel
{
    public IReadOnlyList<AttendanceCorrection> Pending { get; set; } = Array.Empty<AttendanceCorrection>();
    public IReadOnlyList<AttendanceCorrection> History { get; set; } = Array.Empty<AttendanceCorrection>();
}
