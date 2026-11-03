using SebenzaClocking.Core;
using SebenzaClocking.Web.Infrastructure;
using SebenzaClocking.Web.Models;

namespace SebenzaClocking.Web.Services;

public record TodayStats(int Present, int Late, int Completed);

public interface IAttendanceService
{
    Task<IReadOnlyList<AttendanceRecord>> QueryAsync(Guid actorId, DateOnly date, Guid? departmentId, CancellationToken ct = default);
    Task<AttendanceRecord?> GetAsync(Guid actorId, Guid id, CancellationToken ct = default);
    Task<TodayStats> TodayStatsAsync(Guid actorId, CancellationToken ct = default);
    Task<IReadOnlyList<AttendanceRecord>> RecentActivityAsync(Guid actorId, int take, CancellationToken ct = default);
    Task<int[]> PresenceTrendAsync(Guid actorId, int days, CancellationToken ct = default);
}

public class AttendanceService : IAttendanceService
{
    private readonly SebenzaHttp _http;
    public AttendanceService(SebenzaHttp http) => _http = http;

    private const string Select = "select=id,employee_id,clock_in,clock_out,break_minutes,total_hours,overtime_hours,status,employees(id,employee_code,full_name,department_id,role,is_active,departments(id,name))";

    public async Task<IReadOnlyList<AttendanceRecord>> QueryAsync(Guid actorId, DateOnly date, Guid? departmentId, CancellationToken ct = default)
    {
        var from = date.ToString("yyyy-MM-dd");
        var to = date.AddDays(1).ToString("yyyy-MM-dd");
        var q = $"{Select}&clock_in=gte.{from}&clock_in=lt.{to}&order=clock_in.asc&limit=1000";
        var rows = await _http.GetAsync<AttendanceRecord>(actorId, "attendance", q, ct);
        if (departmentId is not null)
            rows = rows.Where(r => r.Emp?.DepartmentId == departmentId).ToList();
        return rows;
    }

    public async Task<AttendanceRecord?> GetAsync(Guid actorId, Guid id, CancellationToken ct = default)
        => (await _http.GetAsync<AttendanceRecord>(actorId, "attendance", $"{Select}&id=eq.{id}", ct)).FirstOrDefault();

    public async Task<TodayStats> TodayStatsAsync(Guid actorId, CancellationToken ct = default)
    {
        var today = Sast.Today;
        var rows = (await QueryAsync(actorId, DateOnly.FromDateTime(today), null, ct)).ToList();
        return new TodayStats(
            Present: rows.Count,
            Late: rows.Count(r => r.IsLate),
            Completed: rows.Count(r => r.ClockOut is not null));
    }

    public async Task<IReadOnlyList<AttendanceRecord>> RecentActivityAsync(Guid actorId, int take, CancellationToken ct = default)
        => await _http.GetAsync<AttendanceRecord>(actorId, "attendance",
            $"{Select}&order=clock_in.desc&limit={Math.Min(take, 50)}", ct);

    public async Task<int[]> PresenceTrendAsync(Guid actorId, int days, CancellationToken ct = default)
    {
        var from = Sast.Today.AddDays(-(days - 1)).ToString("yyyy-MM-dd");
        var rows = await _http.GetAsync<AttendanceRecord>(actorId, "attendance",
            $"select=id,clock_in&clock_in=gte.{from}&limit=1000", ct);
        var result = new int[days];
        for (var i = 0; i < days; i++)
        {
            var d = Sast.Today.AddDays(-(days - 1) + i);
            result[i] = rows.Count(r => Sast.FromUtc(r.ClockIn).Date == d);
        }
        return result;
    }
}
