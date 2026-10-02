# Weatherly

Weatherly is a .NET 10 Blazor Web App with an ASP.NET Core JSON API. The Blazor
server-interactive UI and API share the same forecast service.

Forecast values are generated sample data; no external weather provider or API
key is configured.

## Run locally

From the repository root:

```powershell
dotnet run --project weather-app/WeatherApp.csproj
```

Open the local URL printed by `dotnet run`. The API is available at:

```text
/api/weatherforecast?city=Seattle
```

The `city` query parameter is required and may contain up to 100 characters.
The GitHub Actions workflow builds and publishes `weather-app/WeatherApp.csproj`.
