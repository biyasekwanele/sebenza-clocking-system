using SebenzaClocking.Web.Models;

namespace SebenzaClocking.Web.Services;

public interface ICorrectionService
{
    Task<IReadOnlyList<AttendanceCorrection>> ListAsync(Guid actorId, int take, CancellationToken ct = default);
    Task ReviewAsync(Guid actorId, Guid id, bool approve, CancellationToken ct = default);
}

public class CorrectionService : ICorrectionService
{
    private readonly SebenzaHttp _http;
    private readonly IEmployeeService _employees;

    public CorrectionService(SebenzaHttp http, IEmployeeService employees)
    { _http = http; _employees = employees; }

    public async Task<IReadOnlyList<AttendanceCorrection>> ListAsync(Guid actorId, int take, CancellationToken ct = default)
    {
        var rows = await _http.GetAsync<AttendanceCorrection>(actorId, "attendance_corrections",
            "select=id,attendance_id,employee_id,field,old_value,new_value,reason,status,reviewed_by,reviewed_at,created_at" +
            $"&order=created_at.desc&limit={Math.Min(take, 500)}", ct);

        var emps = (await _employees.ListAsync(actorId, null, includeInactive: true, ct))
            .ToDictionary(e => e.Id);
        foreach (var r in rows)
            if (emps.TryGetValue(r.EmployeeId, out var e))
                r.Emp = new Employee { FullName = e.FullName };
        return rows;
    }

    public async Task ReviewAsync(Guid actorId, Guid id, bool approve, CancellationToken ct = default)
        => await _http.PatchAsync(actorId, "attendance_corrections", $"id=eq.{id}",
            new { status = approve ? "Approved" : "Rejected" }, ct);
}
