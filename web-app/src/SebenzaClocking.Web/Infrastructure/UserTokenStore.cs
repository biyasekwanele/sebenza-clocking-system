using System.Collections.Concurrent;
using System.Security.Claims;

namespace SebenzaClocking.Web.Infrastructure;

public record UserTokens(string AccessToken, string RefreshToken);

/// <summary>
/// Supabase session tokens per employee. Primary: in-memory cache (refreshed
/// tokens live here). Fallback: the sb_access / sb_refresh claims embedded in
/// the encrypted auth cookie at login, so an app restart does NOT force a
/// re-login while the cookie is still valid.
/// </summary>
public interface IUserTokenStore
{
    UserTokens? Get(Guid employeeId);
    void Set(Guid employeeId, UserTokens tokens);
    void Remove(Guid employeeId);
}

public class UserTokenStore : IUserTokenStore
{
    private static readonly ConcurrentDictionary<Guid, UserTokens> Cache = new();
    private readonly IHttpContextAccessor _http;

    public UserTokenStore(IHttpContextAccessor http) => _http = http;

    public UserTokens? Get(Guid employeeId)
    {
        if (Cache.TryGetValue(employeeId, out var cached)) return cached;
        var user = _http.HttpContext?.User;
        var access = user?.FindFirstValue("sb_access");
        var refresh = user?.FindFirstValue("sb_refresh");
        if (string.IsNullOrEmpty(access) || string.IsNullOrEmpty(refresh)) return null;
        var tokens = new UserTokens(access, refresh);
        Cache[employeeId] = tokens;
        return tokens;
    }

    public void Set(Guid employeeId, UserTokens tokens) => Cache[employeeId] = tokens;
    public void Remove(Guid employeeId) => Cache.TryRemove(employeeId, out _);
}
