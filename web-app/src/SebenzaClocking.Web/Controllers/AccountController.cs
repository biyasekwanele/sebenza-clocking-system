using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SebenzaClocking.Core;
using SebenzaClocking.Web.Infrastructure;
using SebenzaClocking.Web.Models;
using SebenzaClocking.Web.Services;

namespace SebenzaClocking.Web.Controllers;

public class AccountController : Controller
{
    private readonly IEmployeeService _employees;
    private readonly SebenzaHttp _http;
    private readonly IUserTokenStore _tokens;

    public AccountController(IEmployeeService employees, SebenzaHttp http, IUserTokenStore tokens)
    { _employees = employees; _http = http; _tokens = tokens; }

    [HttpGet, AllowAnonymous]
    public IActionResult Login(string? returnUrl = null) => View(new LoginViewModel());

    [HttpPost, AllowAnonymous, ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(LoginViewModel vm, string? returnUrl = null)
    {
        if (!ModelState.IsValid) return View(vm);

        Employee? employee;
        try { employee = await _employees.GetByEmailAsync(vm.Email.Trim()); }
        catch (Exception) { employee = null; }
        if (employee is null || !employee.IsActive)
        { ModelState.AddModelError(string.Empty, "Invalid credentials or inactive account."); return View(vm); }

        string access, refresh, userId;
        try { (access, refresh, userId) = await _http.LoginAsync(vm.Email.Trim(), vm.Password); }
        catch (Exception ex)
        { ModelState.AddModelError(string.Empty, ex.Message); return View(vm); }

        if (!Roles.IsManager(employee.Role))
        { ModelState.AddModelError(string.Empty, "Employee accounts use the Sebenza mobile app. This console is for supervisors, HR and administrators."); return View(vm); }

        _tokens.Set(employee.Id, new UserTokens(access, refresh));

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, employee.Id.ToString()),
            new(ClaimTypes.Name, employee.FullName),
            new(ClaimTypes.Role, employee.Role),
            new(ClaimTypes.Email, employee.Email),
            new("department_id", employee.DepartmentId?.ToString() ?? string.Empty),
            new("employee_code", employee.EmployeeCode),
            new("sb_access", access),
            new("sb_refresh", refresh)
        };
        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identity),
            new AuthenticationProperties { IsPersistent = vm.RememberMe, ExpiresUtc = DateTimeOffset.UtcNow.AddHours(9) });

        return LocalRedirect(string.IsNullOrWhiteSpace(returnUrl) ? "/" : returnUrl);
    }

    [Authorize]
    public async Task<IActionResult> Logout()
    {
        if (User.FindFirstValue(ClaimTypes.NameIdentifier) is { } id && Guid.TryParse(id, out var g))
            _tokens.Remove(g);
        await HttpContext.SignOutAsync();
        return RedirectToAction(nameof(Login));
    }
}
