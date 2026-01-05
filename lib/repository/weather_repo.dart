import 'package:weather_app/data/network/network_api_service.dart';
import 'package:weather_app/models/get_weather.dart';

class WeatherRepo {
  var networkApiService = NetworkApiService();

  final String _apiKey = 'bf532a760dc769911a3e43f40150cbc2';

  Future<GetWeather> getWeather(String cityName) async {
    var response = await networkApiService.get(
      'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$_apiKey&units=metric',
    );
    return GetWeather.fromJson(response);
  }
}
