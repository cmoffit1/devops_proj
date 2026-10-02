using WeatherApp.Models;

namespace WeatherApp.Services;

public interface IWeatherForecastService
{
    WeatherForecastResponse GetForecast(string city);
}
