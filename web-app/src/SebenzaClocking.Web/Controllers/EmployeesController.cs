using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using SebenzaClocking.Core;
using SebenzaClocking.Web.Infrastructure;
using SebenzaClocking.Web.Models;
using SebenzaClocking.Web.Services;

namespace SebenzaClocking.Web.Controllers;

[Authorize(Roles = Roles.Admin)]   // FR10: employee management is an administrator function
public class EmployeesController : Controller
{
    private readonly IEmployeeService _employees;
    private readonly ICurrentUserAccessor _user;
    public EmployeesController(IEmployeeService employees, ICurrentUserAccessor user)
    { _employees = employees; _user = user; }

    private Guid ActorId => _user.EmployeeId ?? Guid.Empty;

    public async Task<IActionResult> Index(string? q, CancellationToken ct)
        => View(new EmployeeIndexViewModel { Search = q, Employees = await _employees.ListAsync(ActorId, q, includeInactive: true, ct) });

    private async Task FillAsync(EmployeeFormViewModel vm)
        => vm.Departments = (await _employees.DepartmentsAsync(ActorId))
            .Select(d => new SelectListItem(d.Name, d.Id.ToString())).ToList();

    public async Task<IActionResult> Create()
    { var vm = new EmployeeFormViewModel(); await FillAsync(vm); return View("Form", vm); }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(EmployeeFormViewModel vm, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(vm.Password) || vm.Password.Length < 6)
            ModelState.AddModelError(nameof(vm.Password), "A temporary password of at least 6 characters is required.");
        if (!ModelState.IsValid) { await FillAsync(vm); return View("Form", vm); }
        try
        {
            await _employees.CreateAsync(ActorId, vm, ct);
            TempData["ok"] = $"Employee {vm.EmployeeCode.ToUpperInvariant()} linked to the auth account. Share the password you set in Supabase Dashboard > Authentication.";
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex) { ModelState.AddModelError(string.Empty, ex.Message); await FillAsync(vm); return View("Form", vm); }
    }

    public async Task<IActionResult> Edit(Guid id, CancellationToken ct)
    {
        var e = await _employees.GetAsync(ActorId, id, ct);
        if (e is null) return NotFound();
        var vm = new EmployeeFormViewModel { Id = e.Id, EmployeeCode = e.EmployeeCode, FullName = e.FullName,
            Email = e.Email, Role = e.Role, DepartmentId = e.DepartmentId, IsActive = e.IsActive };
        await FillAsync(vm); return View("Form", vm);
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(EmployeeFormViewModel vm, CancellationToken ct)
    {
        if (!ModelState.IsValid) { await FillAsync(vm); return View("Form", vm); }
        try { await _employees.UpdateAsync(ActorId, vm, ct); TempData["ok"] = "Employee updated."; return RedirectToAction(nameof(Index)); }
        catch (Exception ex) { ModelState.AddModelError(string.Empty, ex.Message); await FillAsync(vm); return View("Form", vm); }
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Deactivate(Guid id, bool active, CancellationToken ct)
    {
        try
        {
            var json = await _employees.SetActiveAsync(ActorId, id, active, ct);
            var nowActive = active;
            try
            {
                using var doc = System.Text.Json.JsonDocument.Parse(json);
                nowActive = doc.RootElement.GetProperty("is_active").GetBoolean();
            }
            catch { /* keep posted value if response parsing fails */ }
            TempData["ok"] = nowActive
                ? "Employee reactivated."
                : "Employee deactivated. Historical records are retained.";
        }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction(nameof(Index));
    }
}
