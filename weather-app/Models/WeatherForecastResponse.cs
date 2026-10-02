namespace WeatherApp.Models;

public sealed record WeatherForecastResponse(
    string City,
    int CurrentTemperatureC,
    IReadOnlyList<DailyForecast> Days);
