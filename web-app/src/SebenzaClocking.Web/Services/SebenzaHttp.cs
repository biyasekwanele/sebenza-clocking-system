using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using SebenzaClocking.Web.Infrastructure;

namespace SebenzaClocking.Web.Services;

public class SebenzaHttp
{
    private readonly HttpClient _http;
    private readonly SupabaseOptions _opt;
    private readonly IUserTokenStore _tokens;
    private static readonly JsonSerializerOptions JsonOpts = new()
    { PropertyNameCaseInsensitive = true, PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower };

    public SebenzaHttp(IHttpClientFactory factory, SupabaseOptions opt, IUserTokenStore tokens)
    { _http = factory.CreateClient("supabase"); _opt = opt; _tokens = tokens; }

    // ------------------------------------------------------------- auth
    public async Task<(string Access, string Refresh, string UserId)> LoginAsync(string email, string password, CancellationToken ct = default)
    {
        var body = await PostAuthAsync("/auth/v1/token?grant_type=password",
            JsonSerializer.Serialize(new { email, password }), ct);
        using var doc = JsonDocument.Parse(body);
        var root = doc.RootElement;
        return (root.GetProperty("access_token").GetString() ?? string.Empty,
                root.GetProperty("refresh_token").GetString() ?? string.Empty,
                root.GetProperty("user").GetProperty("id").GetString() ?? string.Empty);
    }

    public async Task<UserTokens> RefreshAsync(string refreshToken, CancellationToken ct = default)
    {
        var body = await PostAuthAsync("/auth/v1/token?grant_type=refresh_token",
            JsonSerializer.Serialize(new { refresh_token = refreshToken }), ct);
        using var doc = JsonDocument.Parse(body);
        var root = doc.RootElement;
        return new UserTokens(root.GetProperty("access_token").GetString() ?? string.Empty,
                              root.GetProperty("refresh_token").GetString() ?? string.Empty);
    }

    private async Task<string> PostAuthAsync(string path, string json, CancellationToken ct)
    {
        using var req = new HttpRequestMessage(HttpMethod.Post, $"{_opt.Url.TrimEnd('/')}{path}");
        req.Headers.TryAddWithoutValidation("apikey", _opt.AnonKey);
        req.Content = new StringContent(json, Encoding.UTF8, "application/json");
        using var res = await _http.SendAsync(req, ct);
        var body = await res.Content.ReadAsStringAsync(ct);
        if (!res.IsSuccessStatusCode)
            throw new InvalidOperationException("Authentication failed. Check your email and password.");
        return body;
    }

    // --------------------------------------------- authenticated REST/RPC
    private HttpRequestMessage Rest(HttpMethod method, Guid employeeId, string path, string? accessToken)
    {
        var req = new HttpRequestMessage(method, $"{_opt.Url.TrimEnd('/')}{path}");
        req.Headers.TryAddWithoutValidation("apikey", _opt.AnonKey);
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken ?? _opt.AnonKey);
        return req;
    }

    /// <summary>GET a table (or view) with a raw PostgREST query string, e.g. "select=*&status=eq.Pending".</summary>
    public async Task<List<T>> GetAsync<T>(Guid employeeId, string table, string query, CancellationToken ct = default)
    {
        var json = await SendWithRefreshAsync(employeeId, async token =>
        {
            using var req = Rest(HttpMethod.Get, employeeId, $"/rest/v1/{table}?{query}", token);
            using var res = await _http.SendAsync(req, ct);
            var body = await res.Content.ReadAsStringAsync(ct);
            if (!res.IsSuccessStatusCode) throw new SebenzaRequestException(body);
            return body;
        }, ct);
        return JsonSerializer.Deserialize<List<T>>(json, JsonOpts) ?? new List<T>();
    }

    /// <summary>PATCH rows matching a PostgREST filter, with a partial payload.</summary>
    public async Task PatchAsync(Guid employeeId, string table, string filter, object payload, CancellationToken ct = default)
    {
        await SendWithRefreshAsync(employeeId, async token =>
        {
            using var req = Rest(new HttpMethod("PATCH"), employeeId, $"/rest/v1/{table}?{filter}", token);
            req.Headers.TryAddWithoutValidation("Prefer", "return=representation");
            req.Content = new StringContent(JsonSerializer.Serialize(payload, JsonOpts), Encoding.UTF8, "application/json");
            using var res = await _http.SendAsync(req, ct);
            var body = await res.Content.ReadAsStringAsync(ct);
            if (!res.IsSuccessStatusCode) throw new SebenzaRequestException(body);
            return body;
        }, ct);
    }

    /// <summary>Call a security-definer RPC. Argument names must match the SQL function exactly.</summary>
    public async Task<T?> RpcAsync<T>(Guid employeeId, string fn, object args, CancellationToken ct = default)
    {
        var json = await SendWithRefreshAsync(employeeId, async token =>
        {
            using var req = Rest(HttpMethod.Post, employeeId, $"/rest/v1/rpc/{fn}", token);
            req.Content = new StringContent(JsonSerializer.Serialize(args, JsonOpts), Encoding.UTF8, "application/json");
            using var res = await _http.SendAsync(req, ct);
            var body = await res.Content.ReadAsStringAsync(ct);
            if (!res.IsSuccessStatusCode) throw new SebenzaRequestException(body);
            return body;
        }, ct);
        return JsonSerializer.Deserialize<T>(json, JsonOpts);
    }

    /// <summary>Call an RPC with the anon key (pre-login lookups only).</summary>
    public async Task<T?> RpcAnonymousAsync<T>(string fn, object args, CancellationToken ct = default)
    {
        using var req = new HttpRequestMessage(HttpMethod.Post, $"{_opt.Url.TrimEnd('/')}/rest/v1/rpc/{fn}");
        req.Headers.TryAddWithoutValidation("apikey", _opt.AnonKey);
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _opt.AnonKey);
        req.Content = new StringContent(JsonSerializer.Serialize(args, JsonOpts), Encoding.UTF8, "application/json");
        using var res = await _http.SendAsync(req, ct);
        var body = await res.Content.ReadAsStringAsync(ct);
        if (!res.IsSuccessStatusCode) throw new SebenzaRequestException(body);
        return JsonSerializer.Deserialize<T>(body, JsonOpts);
    }

    public async Task<string> RpcRawAsync(Guid employeeId, string fn, object args, CancellationToken ct = default)
        => await SendWithRefreshAsync(employeeId, async token =>
        {
            using var req = Rest(HttpMethod.Post, employeeId, $"/rest/v1/rpc/{fn}", token);
            req.Content = new StringContent(JsonSerializer.Serialize(args, JsonOpts), Encoding.UTF8, "application/json");
            using var res = await _http.SendAsync(req, ct);
            var body = await res.Content.ReadAsStringAsync(ct);
            if (!res.IsSuccessStatusCode) throw new SebenzaRequestException(body);
            return body;
        }, ct);

    /// <summary>Executes the call with the user's token; on 401 refreshes once and retries.</summary>
    private async Task<string> SendWithRefreshAsync(Guid employeeId, Func<string, Task<string>> call, CancellationToken ct)
    {
        var tokens = _tokens.Get(employeeId) ?? throw new InvalidOperationException("Your session has expired. Please sign in again.");
        try { return await call(tokens.AccessToken); }
        catch (SebenzaRequestException ex) when (ex.StatusHint == 401)
        {
            var refreshed = await RefreshAsync(tokens.RefreshToken, ct);
            _tokens.Set(employeeId, refreshed);
            return await call(refreshed.AccessToken);
        }
    }
}

public class SebenzaRequestException : Exception
{
    public int StatusHint { get; }
    public SebenzaRequestException(string body) : base(Friendly(body))
        => StatusHint = body.Contains("401") || body.Contains("JWT") ? 401 : 0;

    private static string Friendly(string body)
    {
        // PostgREST/PostgreSQL error messages are exposed verbatim so that the
        // guard triggers and check constraints read clearly to the reviewer.
        if (string.IsNullOrWhiteSpace(body)) return "The request failed.";
        return body.Trim('"').Length > 300 ? body.Trim('"')[..300] : body.Trim('"');
    }
}
