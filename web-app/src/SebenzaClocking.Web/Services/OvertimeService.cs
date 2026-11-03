using SebenzaClocking.Web.Models;

namespace SebenzaClocking.Web.Services;

public interface IOvertimeService
{
    Task<IReadOnlyList<OvertimeRequest>> ListAsync(Guid actorId, string? status, int take, CancellationToken ct = default);
    Task ReviewAsync(Guid actorId, Guid id, bool approve, CancellationToken ct = default);
}

public class OvertimeService : IOvertimeService
{
    private readonly SebenzaHttp _http;
    private readonly IEmployeeService _employees;

    public OvertimeService(SebenzaHttp http, IEmployeeService employees)
    { _http = http; _employees = employees; }

    public async Task<IReadOnlyList<OvertimeRequest>> ListAsync(Guid actorId, string? status, int take, CancellationToken ct = default)
    {
        var q = "select=id,employee_id,attendance_id,work_date,hours,reason,status,reviewed_by,reviewed_at" +
                $"&order=work_date.desc&limit={Math.Min(take, 500)}";
        if (!string.IsNullOrWhiteSpace(status)) q += $"&status=eq.{status}";

        var rows = await _http.GetAsync<OvertimeRequest>(actorId, "overtime", q, ct);

        // Join employee names in memory: avoids FK-constraint-name ambiguity
        // (overtime has two FKs to employees) and keeps one round trip.
        var emps = (await _employees.ListAsync(actorId, null, includeInactive: true, ct))
            .ToDictionary(e => e.Id);
        foreach (var r in rows)
            if (emps.TryGetValue(r.EmployeeId, out var e))
                r.Emp = new Employee { FullName = e.FullName, DepartmentId = e.DepartmentId,
                                       Dept = e.Dept ?? new Department { Name = e.DepartmentName } };
        return rows;
    }

    /// <summary>
    /// Decision is a status-only UPDATE; guard_review enforces pending-only,
    /// no self-review and stamps the reviewer; apply_decision copies approved
    /// hours onto the attendance record; write_audit logs the change.
    /// </summary>
    public async Task ReviewAsync(Guid actorId, Guid id, bool approve, CancellationToken ct = default)
        => await _http.PatchAsync(actorId, "overtime", $"id=eq.{id}",
            new { status = approve ? "Approved" : "Rejected" }, ct);
}
