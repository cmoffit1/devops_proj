using WeatherApp.Components;
using WeatherApp.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();
builder.Services.AddSingleton<IWeatherForecastService, WeatherForecastService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}
app.UseStatusCodePagesWithReExecute("/not-found", createScopeForStatusCodePages: true);
app.UseHttpsRedirection();

app.UseAntiforgery();

app.MapGet("/api/weatherforecast", (string? city, IWeatherForecastService weatherService) =>
{
    if (string.IsNullOrWhiteSpace(city))
    {
        return Results.BadRequest(new { error = "Provide a city using the 'city' query parameter." });
    }

    var normalizedCity = city.Trim();
    if (normalizedCity.Length > 100)
    {
        return Results.BadRequest(new { error = "City names must be 100 characters or fewer." });
    }

    return Results.Ok(weatherService.GetForecast(normalizedCity));
});

app.MapStaticAssets();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
