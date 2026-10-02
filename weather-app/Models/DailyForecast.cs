namespace WeatherApp.Models;

public sealed record DailyForecast(
    DateOnly Date,
    int HighC,
    int LowC,
    string Summary,
    int Humidity);
