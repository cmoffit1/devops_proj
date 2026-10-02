using WeatherApp.Models;

namespace WeatherApp.Services;

public sealed class WeatherForecastService : IWeatherForecastService
{
    private static readonly string[] Conditions =
    [
        "Sunny",
        "Partly cloudy",
        "Cloudy",
        "Light rain",
        "Showers",
        "Snow"
    ];

    public WeatherForecastResponse GetForecast(string city)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(city);

        var normalizedCity = city.Trim();
        var today = DateOnly.FromDateTime(DateTime.Today);
        var seed = HashCode.Combine(
            StringComparer.OrdinalIgnoreCase.GetHashCode(normalizedCity),
            today.DayNumber);
        var random = new Random(seed);

        var days = Enumerable.Range(0, 5)
            .Select(offset =>
            {
                var high = random.Next(8, 33);
                var low = high - random.Next(4, 13);

                return new DailyForecast(
                    today.AddDays(offset),
                    high,
                    low,
                    Conditions[random.Next(Conditions.Length)],
                    random.Next(35, 91));
            })
            .ToArray();

        return new WeatherForecastResponse(
            normalizedCity,
            days[0].HighC - random.Next(1, 5),
            days);
    }
}
