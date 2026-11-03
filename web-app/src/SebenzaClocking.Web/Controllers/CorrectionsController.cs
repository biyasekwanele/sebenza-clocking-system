using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SebenzaClocking.Core;
using SebenzaClocking.Web.Infrastructure;
using SebenzaClocking.Web.Models;
using SebenzaClocking.Web.Services;

namespace SebenzaClocking.Web.Controllers;

[Authorize(Roles = Roles.Supervisor + "," + Roles.Admin)]
public class CorrectionsController : Controller
{
    private readonly ICorrectionService _corrections;
    private readonly ICurrentUserAccessor _user;
    public CorrectionsController(ICorrectionService corrections, ICurrentUserAccessor user)
    { _corrections = corrections; _user = user; }

    public async Task<IActionResult> Index(CancellationToken ct)
    {
        var all = await _corrections.ListAsync(_user.EmployeeId ?? Guid.Empty, 100, ct);
        return View(new CorrectionsViewModel
        { Pending = all.Where(c => c.Status == "Pending").ToList(),
          History = all.Where(c => c.Status != "Pending").Take(50).ToList() });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Review(Guid id, bool approve, CancellationToken ct)
    {
        try
        {
            await _corrections.ReviewAsync(_user.EmployeeId ?? Guid.Empty, id, approve, ct);
            TempData["ok"] = approve ? "Correction applied to the attendance record." : "Correction rejected.";
        }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction(nameof(Index));
    }
}
