import 'package:weather_app/data/network/network_api_service.dart';
import 'package:weather_app/models/get_weather.dart';

class WeatherRepo {
  var networkApiService = NetworkApiService();

  final String _apiKey = 'YOUR_API_KEY';

  Future<GetWeather> getWeather(String cityName) async {
    var response = await networkApiService.get(
      'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$_apiKey&units=metric',
    );
    return GetWeather.fromJson(response);
  }
}
