using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using SebenzaClocking.Core;
using SebenzaClocking.Web.Infrastructure;
using SebenzaClocking.Web.Models;
using SebenzaClocking.Web.Services;

namespace SebenzaClocking.Web.Controllers;

[Authorize(Roles = Roles.Supervisor + "," + Roles.Admin)]
public class AttendanceController : Controller
{
    private readonly IAttendanceService _attendance;
    private readonly IEmployeeService _employees;
    private readonly ICurrentUserAccessor _user;

    public AttendanceController(IAttendanceService attendance, IEmployeeService employees, ICurrentUserAccessor user)
    { _attendance = attendance; _employees = employees; _user = user; }

    private Guid ActorId => _user.EmployeeId ?? Guid.Empty;

    private async Task FillDepartments(AttendanceListViewModel vm)
    {
        vm.Departments = (await _employees.DepartmentsAsync(ActorId))
            .Select(d => new SelectListItem(d.Name, d.Id.ToString())).ToList();
        vm.Departments.Insert(0, new SelectListItem("All departments", ""));
    }

    public async Task<IActionResult> Index(DateOnly? date, Guid? departmentId, CancellationToken ct)
    {
        var vm = new AttendanceListViewModel
        { Date = date ?? DateOnly.FromDateTime(Sast.Today), DepartmentId = departmentId };
        vm.Records = await _attendance.QueryAsync(ActorId, vm.Date, departmentId, ct);
        await FillDepartments(vm);
        return View(vm);
    }

    public async Task<IActionResult> Detail(Guid id, CancellationToken ct)
        => View(await _attendance.GetAsync(ActorId, id, ct));

    public async Task<IActionResult> Export(DateOnly date, CancellationToken ct)
    {
        var records = await _attendance.QueryAsync(ActorId, date, null, ct);
        var csv = CsvWriter.Write(
            new[] { "Employee Code", "Employee", "Department", "Clock In", "Clock Out", "Break (min)", "Total Hours", "Overtime" },
            records.Select(r => new object?[] { r.EmployeeCode, r.EmployeeName, r.DepartmentName,
                Sast.HHmm(r.ClockIn), r.ClockOut is null ? "—" : Sast.HHmm(r.ClockOut.Value),
                r.BreakMinutes, r.TotalHours?.ToString("0.00"), r.OvertimeHours.ToString("0.00") }));
        return File(Encoding.UTF8.GetBytes(csv), "text/csv", $"attendance_{date:yyyyMMdd}.csv");
    }
}
