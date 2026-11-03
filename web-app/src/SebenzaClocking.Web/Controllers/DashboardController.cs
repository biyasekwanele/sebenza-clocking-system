using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SebenzaClocking.Core;
using SebenzaClocking.Web.Services;

namespace SebenzaClocking.Web.Controllers;

[Authorize(Roles = Roles.Supervisor + "," + Roles.Admin)]
public class DashboardController : Controller
{
    private readonly IDashboardService _dashboard;
    public DashboardController(IDashboardService dashboard) => _dashboard = dashboard;

    public async Task<IActionResult> Index(CancellationToken ct) => View(await _dashboard.BuildAsync(ct));

    /// <summary>Lightweight JSON endpoint polled by the dashboard every 30 s.</summary>
    public async Task<IActionResult> Poll(CancellationToken ct)
    {
        var vm = await _dashboard.BuildAsync(ct);
        return Json(new { vm.Present, vm.Late, vm.Completed, vm.Absent, vm.PendingOvertime });
    }
}
