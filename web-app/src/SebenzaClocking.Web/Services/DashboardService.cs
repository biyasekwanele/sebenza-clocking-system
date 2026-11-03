using SebenzaClocking.Web.Infrastructure;
using SebenzaClocking.Web.Models;

namespace SebenzaClocking.Web.Services;

public interface IDashboardService
{
    Task<DashboardViewModel> BuildAsync(CancellationToken ct = default);
}

public class DashboardService : IDashboardService
{
    private readonly IAttendanceService _attendance;
    private readonly IOvertimeService _overtime;
    private readonly IEmployeeService _employees;
    private readonly ICurrentUserAccessor _user;

    public DashboardService(IAttendanceService attendance, IOvertimeService overtime,
        IEmployeeService employees, ICurrentUserAccessor user)
    { _attendance = attendance; _overtime = overtime; _employees = employees; _user = user; }

    public async Task<DashboardViewModel> BuildAsync(CancellationToken ct = default)
    {
        const int days = 14;
        var actorId = _user.EmployeeId ?? Guid.Empty;
        var stats = await _attendance.TodayStatsAsync(actorId, ct);
        var headcount = (await _employees.ListActiveAsync(actorId, ct)).Count;
        var trend = await _attendance.PresenceTrendAsync(actorId, days, ct);
        var activity = await _attendance.RecentActivityAsync(actorId, 12, ct);
        var pending = await _overtime.ListAsync(actorId, "Pending", 5, ct);
        var labels = Enumerable.Range(0, days)
            .Select(i => Sast.Today.AddDays(-(days - 1) + i).ToString("dd/MM")).ToArray();
        return new DashboardViewModel
        {
            Present = stats.Present, Late = stats.Late, Completed = stats.Completed,
            Absent = Math.Max(0, headcount - stats.Present),
            PendingOvertime = pending.Count,
            Activity = activity, RecentOvertime = pending, Trend = trend, TrendLabels = labels
        };
    }
}
