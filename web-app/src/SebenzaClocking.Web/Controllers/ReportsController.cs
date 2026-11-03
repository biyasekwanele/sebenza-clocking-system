using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SebenzaClocking.Core;
using SebenzaClocking.Web.Infrastructure;
using SebenzaClocking.Web.Services;

namespace SebenzaClocking.Web.Controllers;

[Authorize(Roles = Roles.Supervisor + "," + Roles.Admin)]
public class ReportsController : Controller
{
    private readonly IReportingService _reporting;
    private readonly ICurrentUserAccessor _user;
    public ReportsController(IReportingService reporting, ICurrentUserAccessor user)
    { _reporting = reporting; _user = user; }

    public IActionResult Index()
    {
        var today = DateOnly.FromDateTime(Sast.Today);
        ViewBag.From = new DateOnly(today.Year, today.Month, 1).ToString("yyyy-MM-dd");
        ViewBag.To = today.ToString("yyyy-MM-dd");
        return View();
    }

    public async Task<IActionResult> Export(string type, DateOnly from, DateOnly to, string format, CancellationToken ct)
    {
        if (to < from) (from, to) = (to, from);
        if ((to.ToDateTime(TimeOnly.MinValue) - from.ToDateTime(TimeOnly.MinValue)).TotalDays > 93)
        { TempData["err"] = "Date range is limited to 93 days."; return RedirectToAction(nameof(Index)); }
        var (bytes, contentType, fileName) = await _reporting.ExportAsync(
            _user.EmployeeId ?? Guid.Empty, type, from, to, format, ct);
        return File(bytes, contentType, fileName);
    }
}

[Authorize(Roles = Roles.Admin)]
public class AuditController : Controller
{
    private readonly IAuditService _audit;
    private readonly ICurrentUserAccessor _user;
    public AuditController(IAuditService audit, ICurrentUserAccessor user)
    { _audit = audit; _user = user; }

    public async Task<IActionResult> Index(string? entity)
    {
        ViewBag.Entity = entity;
        ViewBag.Entities = new[] { "attendance", "overtime", "attendance_corrections", "employees" };
        return View(await _audit.ListAsync(_user.EmployeeId ?? Guid.Empty, entity, 200));
    }
}

[AllowAnonymous]
public class ErrorController : Controller
{
    public IActionResult Index() => View("Error");
}
