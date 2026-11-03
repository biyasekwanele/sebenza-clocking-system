using System.Security.Claims;
using SebenzaClocking.Core;

namespace SebenzaClocking.Web.Infrastructure;

public interface ICurrentUserAccessor
{
    Guid? EmployeeId { get; }
    string? FullName { get; }
    string? Role { get; }
    Guid? DepartmentId { get; }
    bool IsAdmin { get; }
    bool IsManager { get; }
}

public class CurrentUserAccessor : ICurrentUserAccessor
{
    private readonly IHttpContextAccessor _http;
    public CurrentUserAccessor(IHttpContextAccessor http) => _http = http;
    private ClaimsPrincipal? User => _http.HttpContext?.User;

    public Guid? EmployeeId =>
        Guid.TryParse(User?.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : null;
    public string? FullName => User?.FindFirstValue(ClaimTypes.Name);
    public string? Role => User?.FindFirstValue(ClaimTypes.Role);
    public Guid? DepartmentId =>
        Guid.TryParse(User?.FindFirstValue("department_id"), out var id) ? id : null;
    public bool IsAdmin => string.Equals(Role, Roles.Admin, StringComparison.OrdinalIgnoreCase);
    public bool IsManager => Roles.IsManager(Role);
}
