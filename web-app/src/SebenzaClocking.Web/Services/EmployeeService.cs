using SebenzaClocking.Web.Models;

namespace SebenzaClocking.Web.Services;

public interface IEmployeeService
{
    Task<IReadOnlyList<Employee>> ListAsync(Guid actorId, string? search, bool includeInactive, CancellationToken ct = default);
    Task<IReadOnlyList<Employee>> ListActiveAsync(Guid actorId, CancellationToken ct = default);
    Task<Employee?> GetAsync(Guid actorId, Guid id, CancellationToken ct = default);
    Task<Employee?> GetByEmailAsync(string email, CancellationToken ct = default);
    Task<IReadOnlyList<Department>> DepartmentsAsync(Guid actorId, CancellationToken ct = default);
    Task CreateAsync(Guid actorId, EmployeeFormViewModel vm, CancellationToken ct = default);
    Task UpdateAsync(Guid actorId, EmployeeFormViewModel vm, CancellationToken ct = default);
    Task<string> SetActiveAsync(Guid actorId, Guid id, bool active, CancellationToken ct = default);
}

public class EmployeeService : IEmployeeService
{
    private readonly SebenzaHttp _http;
    public EmployeeService(SebenzaHttp http) => _http = http;

    private const string Select = "select=id,user_id,employee_code,full_name,email,department_id,role,is_active,departments(id,name)";

    public async Task<IReadOnlyList<Employee>> ListAsync(Guid actorId, string? search, bool includeInactive, CancellationToken ct = default)
    {
        var q = Select + "&order=full_name.asc&limit=500";
        if (!includeInactive) q += "&is_active=eq.true";
        if (!string.IsNullOrWhiteSpace(search))
            q += $"&or=(full_name.ilike.*{search}*,employee_code.ilike.*{search}*)";
        return await _http.GetAsync<Employee>(actorId, "employees", q, ct);
    }

    public async Task<IReadOnlyList<Employee>> ListActiveAsync(Guid actorId, CancellationToken ct = default)
        => await ListAsync(actorId, null, includeInactive: false, ct);

    public async Task<Employee?> GetAsync(Guid actorId, Guid id, CancellationToken ct = default)
        => (await _http.GetAsync<Employee>(actorId, "employees", $"{Select}&id=eq.{id}", ct)).FirstOrDefault();

    // Pre-login lookup goes through the anonymous security-definer RPC,
    // because RLS blocks employee reads for unauthenticated callers.
    private record LoginLookupDto(Guid Id, string FullName, string Role,
        Guid? DepartmentId, bool IsActive, string EmployeeCode);

    public async Task<Employee?> GetByEmailAsync(string email, CancellationToken ct = default)
    {
        var rows = await _http.RpcAnonymousAsync<List<LoginLookupDto>>(
            "login_lookup", new { p_email = email }, ct);
        var dto = rows?.FirstOrDefault();
        if (dto is null) return null;
        return new Employee
        {
            Id = dto.Id, FullName = dto.FullName, Role = dto.Role,
            DepartmentId = dto.DepartmentId, IsActive = dto.IsActive,
            EmployeeCode = dto.EmployeeCode, Email = email.Trim().ToLowerInvariant()
        };
    }

    public async Task<IReadOnlyList<Department>> DepartmentsAsync(Guid actorId, CancellationToken ct = default)
        => await _http.GetAsync<Department>(actorId, "departments", "select=id,name&order=name.asc", ct);

    public async Task CreateAsync(Guid actorId, EmployeeFormViewModel vm, CancellationToken ct = default)
        => await _http.RpcRawAsync(actorId, "admin_create_employee", new
        { p_code = vm.EmployeeCode, p_full_name = vm.FullName, p_email = vm.Email,
          p_role = vm.Role, p_department_id = vm.DepartmentId, p_password = vm.Password }, ct);

    public async Task UpdateAsync(Guid actorId, EmployeeFormViewModel vm, CancellationToken ct = default)
        => await _http.RpcRawAsync(actorId, "admin_update_employee", new
        { p_id = vm.Id, p_code = vm.EmployeeCode, p_full_name = vm.FullName, p_email = vm.Email,
          p_role = vm.Role, p_department_id = vm.DepartmentId, p_is_active = (bool?)null }, ct);

    public async Task<string> SetActiveAsync(Guid actorId, Guid id, bool active, CancellationToken ct = default)
        => await _http.RpcRawAsync(actorId, "admin_update_employee", new
        { p_id = id, p_code = "", p_full_name = "", p_email = "", p_role = "employee",
          p_department_id = (Guid?)null, p_is_active = active }, ct);
}
