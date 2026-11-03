using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SebenzaClocking.Core;
using SebenzaClocking.Web.Infrastructure;
using SebenzaClocking.Web.Services;

namespace SebenzaClocking.Web.Controllers;

[Authorize(Roles = Roles.Supervisor + "," + Roles.Admin)]
public class OvertimeController : Controller
{
    private readonly IOvertimeService _overtime;
    private readonly ICurrentUserAccessor _user;
    public OvertimeController(IOvertimeService overtime, ICurrentUserAccessor user)
    { _overtime = overtime; _user = user; }

    public async Task<IActionResult> Index(CancellationToken ct)
        => View(await _overtime.ListAsync(_user.EmployeeId ?? Guid.Empty, null, 100, ct));

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Review(Guid id, bool approve, CancellationToken ct)
    {
        try
        {
            await _overtime.ReviewAsync(_user.EmployeeId ?? Guid.Empty, id, approve, ct);
            TempData["ok"] = approve ? "Overtime request approved." : "Overtime request rejected.";
        }
        catch (Exception ex) { TempData["err"] = $"Could not record the decision: {ex.Message}"; }
        return RedirectToAction(nameof(Index));
    }
}
