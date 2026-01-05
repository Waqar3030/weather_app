import 'package:get/get.dart';
import 'package:weather_app/models/get_weather.dart';
import 'package:weather_app/repository/weather_repo.dart';

class WeatherController extends GetxController {
  var repo = WeatherRepo();
  GetWeather getweather = GetWeather();
  var isLoading = false;

  getWeather(String cityName) async {
    try {
      isLoading = true;
      var result = await repo.getWeather(cityName);
      getweather = result;
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch weather');
    } finally {
      isLoading = false;
      update();
    }
  }
}
