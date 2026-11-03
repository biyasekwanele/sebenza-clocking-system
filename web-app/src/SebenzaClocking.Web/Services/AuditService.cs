using SebenzaClocking.Web.Models;

namespace SebenzaClocking.Web.Services;

public interface IAuditService
{
    Task<IReadOnlyList<AuditLogEntry>> ListAsync(Guid actorId, string? entity, int take, CancellationToken ct = default);
}

public class AuditService : IAuditService
{
    private readonly SebenzaHttp _http;
    private readonly IEmployeeService _employees;
    public AuditService(SebenzaHttp http, IEmployeeService employees)
    { _http = http; _employees = employees; }

    public async Task<IReadOnlyList<AuditLogEntry>> ListAsync(Guid actorId, string? entity, int take, CancellationToken ct = default)
    {
        var q = "select=id,actor_id,entity,entity_id,action,details,created_at" +
                $"&order=created_at.desc&limit={Math.Min(take, 500)}";
        if (!string.IsNullOrWhiteSpace(entity)) q += $"&entity=eq.{entity}";
        var rows = await _http.GetAsync<AuditLogEntry>(actorId, "audit_log", q, ct);
        var names = (await _employees.ListAsync(actorId, null, includeInactive: true, ct))
            .ToDictionary(e => e.Id, e => e.FullName);
        foreach (var r in rows)
            if (r.ActorId is not null && names.TryGetValue(r.ActorId.Value, out var n)) r.Actor = new Employee { FullName = n };
        return rows;
    }
}
