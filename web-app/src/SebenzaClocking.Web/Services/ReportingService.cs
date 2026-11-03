using System.Text;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using SebenzaClocking.Core;
using SebenzaClocking.Web.Infrastructure;
using SebenzaClocking.Web.Models;

namespace SebenzaClocking.Web.Services;

public interface IReportingService
{
    Task<(byte[] Bytes, string ContentType, string FileName)> ExportAsync(
        Guid actorId, string type, DateOnly from, DateOnly to, string format, CancellationToken ct = default);
}

public class ReportingService : IReportingService
{
    private readonly IAttendanceService _attendance;
    private readonly IOvertimeService _overtime;
    private readonly IEmployeeService _employees;

    public ReportingService(IAttendanceService attendance, IOvertimeService overtime, IEmployeeService employees)
    { _attendance = attendance; _overtime = overtime; _employees = employees; }

    public async Task<(byte[], string, string)> ExportAsync(Guid actorId, string type, DateOnly from, DateOnly to, string format, CancellationToken ct = default)
    {
        var rows = new List<string[]>();
        var title = type switch
        {
            "late" => "Late Arrival Report",
            "overtime" => "Overtime Summary",
            "roster" => "Employee Roster",
            _ => "Attendance Summary"
        };

        if (type == "overtime")
        {
            rows.Add(new[] { "Work Date", "Employee", "Department", "Hours", "Status", "Reviewed At" });
            foreach (var r in await _overtime.ListAsync(actorId, null, 5000, ct))
                if (DateOnly.FromDateTime(Sast.FromUtc(r.WorkDate)) >= from
                    && DateOnly.FromDateTime(Sast.FromUtc(r.WorkDate)) <= to)
                    rows.Add(new[] { Sast.Date(r.WorkDate), r.EmployeeName, r.DepartmentName,
                        r.Hours.ToString("0.00"), r.Status,
                        r.ReviewedAt is null ? "" : Sast.DateTime(r.ReviewedAt.Value) });
        }
        else if (type == "roster")
        {
            rows.Add(new[] { "Employee Code", "Employee", "Department", "Role", "Status" });
            foreach (var e in await _employees.ListActiveAsync(actorId, ct))
                rows.Add(new[] { e.EmployeeCode, e.FullName, e.DepartmentName, e.Role,
                    e.ClockedInToday ? "IN" : "OUT" });
        }
        else
        {
            rows.Add(new[] { "Date", "Employee Code", "Employee", "Department", "Clock In", "Clock Out",
                "Break (min)", "Total Hours", "Overtime Hours", "Status" });
            for (var d = from; d <= to; d = d.AddDays(1))
            {
                var day = await _attendance.QueryAsync(actorId, d, null, ct);
                foreach (var r in day)
                {
                    if (type == "late" && !r.IsLate) continue;
                    rows.Add(new[] { Sast.Date(r.ClockIn), r.EmployeeCode, r.EmployeeName, r.DepartmentName,
                        Sast.HHmm(r.ClockIn), r.ClockOut is null ? "—" : Sast.HHmm(r.ClockOut.Value),
                        r.BreakMinutes.ToString(), r.TotalHours?.ToString("0.00") ?? "—",
                        r.OvertimeHours.ToString("0.00"), r.Status });
                }
            }
        }

        var safe = title.Replace(" ", "_");
        if (format.Equals("pdf", StringComparison.OrdinalIgnoreCase))
            return (BuildPdf(title, rows), "application/pdf", $"{safe}_{from:yyyyMMdd}_{to:yyyyMMdd}.pdf");
        return (Encoding.UTF8.GetBytes(CsvWriter.Write(rows[0], rows.Skip(1))),
            "text/csv", $"{safe}_{from:yyyyMMdd}_{to:yyyyMMdd}.csv");
    }

    private static byte[] BuildPdf(string title, List<string[]> rows)
        => Document.Create(doc => doc.Page(page =>
        {
            page.Size(PageSizes.A4.Landscape());
            page.Margin(28);
            page.DefaultTextStyle(x => x.FontSize(9));
            page.Header().Text($"{title} — Sebenza Clocking System").FontSize(15).SemiBold();
            page.Content().PaddingTop(10).Table(table =>
            {
                table.ColumnsDefinition(c => { foreach (var _ in rows[0]) c.RelativeColumn(); });
                table.Header(h => { foreach (var col in rows[0]) h.Cell().Background("#F0A232").Text(col).SemiBold(); });
                foreach (var row in rows.Skip(1)) { foreach (var cell in row) table.Cell().Text(cell); }
            });
            page.Footer().AlignRight().Text(t =>
            { t.Span("Generated "); t.Span(DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm UTC")); });
        })).GeneratePdf();
}
