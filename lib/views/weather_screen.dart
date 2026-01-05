import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/controllers/weather_controller.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with TickerProviderStateMixin {
  String iconCode = "";
  final weatherController = Get.put(WeatherController());
  final TextEditingController searchController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    weatherController.getWeather("Islamabad");

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E3C72),
              const Color(0xFF2A5298),
              const Color(0xFF7E22CE),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildSearchBar(),
              Expanded(
                child: GetBuilder<WeatherController>(
                  builder: (controller) {
                    if (controller.isLoading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                            20.h.verticalSpace,
                            Text(
                              "Fetching weather data...",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final weather = controller.getweather;
                    iconCode =
                        (weather.weather != null &&
                                weather.weather!.isNotEmpty &&
                                weather.weather![0].icon != null)
                            ? weather.weather![0].icon!
                            : "";

                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildWeatherContent(weather),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weather',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                DateFormat('EEEE, d MMMM').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: () {
                _fadeController.reset();
                _slideController.reset();
                final city =
                    searchController.text.trim().isNotEmpty
                        ? searchController.text.trim()
                        : "Islamabad";
                weatherController.getWeather(city);
                _fadeController.forward();
                _slideController.forward();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: TextField(
          controller: searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search for a city...',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 15.sp,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: 22,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.my_location_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 22,
              ),
              onPressed: () {
                searchController.text = "Islamabad";
                weatherController.getWeather("Islamabad");
                FocusScope.of(context).unfocus();
              },
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              vertical: 16.h,
              horizontal: 16.w,
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _fadeController.reset();
              _slideController.reset();
              weatherController.getWeather(value.trim());
              _fadeController.forward();
              _slideController.forward();
              FocusScope.of(context).unfocus();
            }
          },
        ),
      ),
    );
  }

  Widget _buildWeatherContent(weather) {
    final now = DateTime.now();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            20.h.verticalSpace,
            _buildMainWeatherCard(weather),
            25.h.verticalSpace,
            _buildQuickStats(weather),
            25.h.verticalSpace,
            Text(
              "Additional Details",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            15.h.verticalSpace,
            _buildDetailsGrid(weather),
            30.h.verticalSpace,
            Center(
              child: Text(
                "Last updated: ${DateFormat('HH:mm').format(now)}",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            30.h.verticalSpace,
          ],
        ),
      ),
    );
  }

  Widget _buildMainWeatherCard(weather) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
              5.w.horizontalSpace,
              Text(
                weather.name ?? "Unknown",
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          25.h.verticalSpace,
          iconCode.isNotEmpty
              ? Image.network(
                'https://openweathermap.org/img/wn/$iconCode@4x.png',
                width: 140.w,
                height: 140.h,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.wb_cloudy_rounded,
                    size: 100.sp,
                    color: Colors.white,
                  );
                },
              )
              : Icon(
                Icons.wb_cloudy_rounded,
                size: 100.sp,
                color: Colors.white,
              ),
          15.h.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weather.main?.temp?.toStringAsFixed(0) ?? "--",
                style: TextStyle(
                  fontSize: 85.sp,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                "°",
                style: TextStyle(
                  fontSize: 50.sp,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          5.h.verticalSpace,
          Text(
            weather.weather?[0].description?.toUpperCase() ?? "--",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 2,
            ),
          ),
          5.h.verticalSpace,
          Text(
            "Feels like ${weather.main?.feelsLike?.toStringAsFixed(0) ?? "--"}°",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(weather) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.water_drop_rounded,
            "${weather.main?.humidity ?? "--"}%",
            "Humidity",
            const Color(0xFF3B82F6),
          ),
        ),
        15.w.horizontalSpace,
        Expanded(
          child: _buildStatCard(
            Icons.air_rounded,
            "${weather.wind?.speed ?? "--"}",
            "Wind (m/s)",
            const Color(0xFF8B5CF6),
          ),
        ),
        15.w.horizontalSpace,
        Expanded(
          child: _buildStatCard(
            Icons.compress_rounded,
            "${weather.main?.pressure ?? "--"}",
            "Pressure",
            const Color(0xFFEC4899),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          12.h.verticalSpace,
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          4.h.verticalSpace,
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(weather) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                Icons.thermostat_rounded,
                "Max Temp",
                "${weather.main?.tempMax?.toStringAsFixed(1) ?? "--"}°C",
                const Color(0xFFEF4444),
              ),
            ),
            15.w.horizontalSpace,
            Expanded(
              child: _buildDetailCard(
                Icons.thermostat_rounded,
                "Min Temp",
                "${weather.main?.tempMin?.toStringAsFixed(1) ?? "--"}°C",
                const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        15.h.verticalSpace,
        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                Icons.visibility_rounded,
                "Visibility",
                "${(weather.visibility ?? 0) / 1000} km",
                const Color(0xFF10B981),
              ),
            ),
            15.w.horizontalSpace,
            Expanded(
              child: _buildDetailCard(
                Icons.wb_sunny_rounded,
                "UV Index",
                "Moderate",
                const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          12.h.verticalSpace,
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          5.h.verticalSpace,
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
