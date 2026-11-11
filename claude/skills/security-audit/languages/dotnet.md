# .NET Security Guide (ASP.NET Web Forms, MVC, Core, Razor, Blazor, EF)

Local addition to the adapted `security-audit` skill (not part of the upstream Sentry skill).
Framework behavior below was checked against Microsoft Learn on 2026-11-11:
EF Core SQL queries, ASP.NET Core XSS prevention, `Path.Combine`, the
BinaryFormatter security guide, `Label.Text` and `Literal.Mode`. Confirm
version-specific behavior in the project's actual framework version.

## Attacker-Controlled vs Server-Controlled

| Attacker-controlled (investigate) | Server-controlled (usually safe) |
| --- | --- |
| `Request.QueryString`, `Request.Form`, `Request.Cookies`, `Request.Headers`, `Request["x"]` | `IConfiguration`, `appsettings*.json`, `IOptions<T>` |
| MVC/Core model binding: action parameters, `[FromQuery]`, `[FromBody]`, `[FromRoute]`, `[FromForm]` | `Web.config` `appSettings` / `connectionStrings`, `ConfigurationManager.AppSettings` |
| Web Forms control values (`TextBox.Text`, `DropDownList.SelectedValue`, hidden fields) | Environment variables, constants |
| Uploaded files: `IFormFile`, `HttpPostedFile` (content **and** `FileName`) | Values computed on the server from trusted data |
| `.ashx` handlers, `[WebMethod]` page methods, Web API and SignalR hub arguments | Signed/encrypted data validated by the framework |
| Data written by other users and read back from the database | |

## SQL Injection

| Pattern | Verdict |
| --- | --- |
| `new SqlCommand("... WHERE Id = " + id)` or `$"... {id}"` with input | **Flag** |
| `cmd.Parameters.AddWithValue("@id", id)` / `SqlParameter` | Safe |
| EF Core LINQ (`Where`, `Find`, ...) | Safe (parameterized) |
| EF Core `FromSql($"...{x}")`, `FromSqlInterpolated`, `ExecuteSql($"...")`, `SqlQuery<T>($"...")` | Safe: interpolated values become `DbParameter`s |
| EF Core `FromSqlRaw`, `ExecuteSqlRaw`, `SqlQueryRaw` with concatenated or interpolated input | **Flag** |
| Dynamic column/table names chosen by the user | **Flag** unless mapped through an allowlist |
| Dapper with anonymous-object parameters | Safe; flag string-built SQL |
| `SqlDataSource` with `SelectCommand` built from input | **Flag**; parameters in markup are safe |
| Stored procedures that build dynamic SQL with `EXEC(@sql)` from parameters | **Flag** the procedure (check `sp_executesql` with parameters) |

## XSS

| Pattern | Verdict |
| --- | --- |
| Razor `@value` | Encoded by default (HTML-attribute rules) |
| `@Html.Raw(input)`, `new HtmlString(input)`, `MvcHtmlString.Create(input)` | **Flag** |
| Razor `@value` inside `<script>` blocks | **Flag**: wrong context; prefer `data-*` attributes or `JavaScriptEncoder` |
| Blazor `@value` | Encoded |
| Blazor `(MarkupString)input` | **Flag** |
| Web Forms `<%: value %>` / `<%#: value %>` | Encoded |
| Web Forms `<%= value %>`, `<%# value %>`, `Response.Write(input)` | **Flag** if input reaches it |
| Web Forms `Label.Text = input` | **Flag**: HTML passes to the browser unchanged |
| `Literal.Text = input` with default `Mode` (`Transform`) or `PassThrough` | **Flag**; `Mode="Encode"` or `HttpUtility.HtmlEncode` is safe |
| Request validation (`ValidateRequest`, `requestValidationMode`) | Partial defense only; never accept it as the XSS control |

Encode at the point of output, using the encoder for the target context (HTML, attribute, JavaScript, URL).

## Authorization and CSRF

- Core/MVC: check `[Authorize]` / policies on controllers and actions, and `[AllowAnonymous]` overrides. Web Forms: check `<authorization>` in `Web.config` (including `<location>` blocks) and page-level checks in code-behind.
- IDOR: handlers, `[WebMethod]`s and actions that load records by id must filter by the current user, tenant or role.
- CSRF: MVC `[ValidateAntiForgeryToken]` / Core antiforgery on state-changing endpoints; Web Forms `ViewStateUserKey` per user. `.ashx`, `[WebMethod]` and JSON endpoints usually bypass these protections. Verify them explicitly.

## Deserialization

- Flag `BinaryFormatter`, `SoapFormatter`, `NetDataContractSerializer`, `LosFormatter` and `ObjectStateFormatter` on any data that crosses a trust boundary. Microsoft states they cannot be made safe. In .NET 9+, the in-box `BinaryFormatter` throws on use.
- Web Forms: `enableViewStateMac="false"` or a leaked `machineKey` turns ViewState into a deserialization vector.
- Json.NET `TypeNameHandling` other than `None` on untrusted input: **flag**. `JavaScriptSerializer` with a `SimpleTypeResolver`: **flag**.
- Safe defaults: `System.Text.Json`, `DataContractSerializer`, `XmlSerializer` with fixed types.

## Files, Paths and XML

- `Path.Combine(baseDir, userInput)`: a rooted `userInput` discards `baseDir`, and `..` segments escape it. Flag unless the result is normalized with `Path.GetFullPath` and checked to stay under the base. Prefer `Path.Join` on .NET Core and later.
- `Server.MapPath(input)`, `File.ReadAllBytes(input)`, `Response.TransmitFile(input)` with input: flag without that containment check.
- Uploads: never trust the client `FileName` or content type. Check for an extension allowlist, size limits (`maxRequestLength`, `RequestSizeLimit`) and storage outside the web root.
- XXE: `XmlDocument` with a non-null `XmlResolver`, or `XmlReaderSettings.DtdProcessing = Parse`, on untrusted XML. Flag (behavior depends on the target framework version).

## Secrets and Configuration

- Credentials in `Web.config`/`appsettings*.json` committed to VCS: report the location only, never the value.
- Production config with `<compilation debug="true">`, `<customErrors mode="Off">`, `<trace enabled="true">`, or `app.UseDeveloperExceptionPage()` outside development: flag.
- Cookies: `HttpOnly`, `Secure` (`requireSSL`), `SameSite` on auth/session cookies.

## Crypto and Randomness

- Password storage with `MD5`, `SHA1`, `SHA256` (unsalted, fast): flag. Use the ASP.NET Identity password hasher or PBKDF2 (`Rfc2898DeriveBytes`) with a high iteration count.
- `System.Random` for tokens, reset codes or ids: flag. Use `RandomNumberGenerator`.
- Hard-coded keys/IVs: flag.

## Redirects and Processes

- `Response.Redirect(input)` / `Redirect(input)`: flag unless checked with `Url.IsLocalUrl` or an allowlist.
- `Process.Start` with input in the file name or arguments (especially via `cmd.exe /c`): flag.
