import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:weather_app/resources/local%20storage/local_storage.dart';
import 'package:weather_app/resources/local%20storage/local_storage_keys.dart';

class Utils {
  static logSuccess(String msg, {String? name}) {
    log(
      '\x1B[32m$msg\x1B[0m',
      name: name != null ? '\x1B[32m$name\x1B[0m' : "",
    );
  }

  static logError(String msg, {String? name}) {
    log(
      '\x1B[31m$msg\x1B[0m',
      name: name != null ? '\x1B[31m$name\x1B[0m' : "",
    );
  }

  static logInfo(String msg, {String? name}) {
    log(
      '\x1B[37m$msg\x1B[0m',
      name: name != null ? '\x1B[37m$name\x1B[0m' : "",
    );
  }

  static Widget showEmptyError({
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xff2C2918),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xffFFDD31), width: 2),
        ),
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            Icon(Icons.error, color: Colors.white, size: 40),
            10.h.verticalSpace,
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            5.h.verticalSpace,
            Text(
              subtitle,
              style: TextStyle(fontSize: 15.sp, color: const Color(0xffFFDD31)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static Future firstTimeSetup({
    required Function() onFirstTime,
    required Function() onNotFirstTime,
  }) async {
    try {
      bool? isFirstTime = LocalStorage.readJson(key: lsk.isFirstTime);

      logSuccess('Read isFirstTime value from local storage: $isFirstTime');

      if (isFirstTime == null) {
        logSuccess('First time setup logic is executed.');
        onFirstTime();
        LocalStorage.saveJson(key: lsk.isFirstTime, value: false);

        bool? updatedValue = LocalStorage.readJson(key: lsk.isFirstTime);
        logSuccess(
          'Updated isFirstTime value in local storage to $updatedValue.',
        );
      } else {
        logSuccess('Non-first-time setup logic is executed.');
        onNotFirstTime();
      }
    } catch (e) {
      logError('An error occurred in firstTimeSetup: $e');
    }
  }

  static selectImagePickerTypeModal({
    required BuildContext context,
    required Function(List<PlatformFile>) onFileSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.r),
              topRight: Radius.circular(25.r),
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Camera'),
                onTap: () async {
                  Get.close(1);

                  final XFile? result = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                  );

                  if (result != null) {
                    File file = File(result.path);
                    PlatformFile platformFile = PlatformFile(
                      path: result.path,
                      name: file.path.split('/').last,
                      size: await file.length(),
                      bytes: await file.readAsBytes(),
                    );

                    int sizeInBytes = platformFile.size;
                    double sizeInMb = sizeInBytes / (1024 * 1024);

                    if (sizeInMb < 100) {
                      // Use the callback to pass the selected file back to the parent
                      onFileSelected([platformFile]);
                      log(
                        "Selected File List from Camera ${File(platformFile.path!)}",
                      );
                    } else {
                      Get.snackbar("Error", 'Captured image is too large');
                    }
                  } else {
                    Get.snackbar("Error", "No image selected");
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Get.close(1);
                  pickFile(onFileSelected: onFileSelected);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static logC(String msg, {String? name}) {
    final random = math.Random();
    final colorCode = 30 + random.nextInt(7);
    log(
      '\x1B[${colorCode}m$msg\x1B[0m',
      name: name != null ? '\x1B[${colorCode}m$name\x1B[0m' : "",
    );
  }

  static selectDate(
    BuildContext context, {
    required Function(DateTime) onDateSelected,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2040),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  static selectTime(
    BuildContext context, {
    required Function(DateTime) onTimeSelected,
    TimeOfDay? initialTime,
  }) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      // Construct a DateTime object with the current date and selected time
      final DateTime selectedTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Trigger the callback with the selected time
      onTimeSelected(selectedTime);
    }
  }

  static Future<void> pickProfileImage({
    required ImageSource source,
    required Function(File) onFileSelected,
  }) async {
    ImagePicker _picker = ImagePicker();
    File? selectedFile;
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        selectedFile = File(pickedFile.path);
        onFileSelected(selectedFile);
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  static pickFile({
    required Function(List<PlatformFile>) onFileSelected,
  }) async {
    try {
      FilePickerResult? result;

      if (Platform.isIOS) {
        result = await FilePicker.platform.pickFiles(
          allowCompression: true,
          type: FileType.media,
        );
      } else {
        result = await FilePicker.platform.pickFiles(
          allowCompression: true,
          type: FileType.custom,
          allowedExtensions: ['mp4', 'png', 'jpeg', 'jpg'],
        );
      }

      if (result != null) {
        List<PlatformFile> newFiles = [];

        for (var element in result.files) {
          int sizeInBytes = element.size;
          double sizeInMb = sizeInBytes / (1024 * 1024);
          if (sizeInMb < 100) {
            newFiles.add(element);
            log("Selected File List ${File(element.path!)}");
          } else {
            Get.snackbar("Error", 'Selected file is too large');
          }
        }

        // Use the callback to pass the new files back to the parent
        onFileSelected(newFiles);
      }
    } catch (e) {
      print(e);
    }
  }

  static successBar(String message) {
    return Get.snackbar(
      "Success",
      snackPosition: SnackPosition.TOP,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  static errorBar(String message) {
    return Get.snackbar(
      "Error",
      snackPosition: SnackPosition.TOP,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
    );
  }

  static void fieldFocusChange(
    BuildContext context,
    FocusNode current,
    FocusNode nextFocus,
  ) {
    current.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  static showSnack(String msg, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating, //! For Bottom
      ),
    );
  }

  static showLoaderAlert(BuildContext context) {
    Get.dialog(
      // context: context,
      // barrierDismissible: false,
      // : (BuildContext context) {
      const Center(child: CircularProgressIndicator(color: Colors.yellow)),
      // },
    );
  }

  static closeShowLoaderAlert(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  static showLoading({double height = 25, double width = 25, Color? color}) {
    return Center(
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: CircularProgressIndicator(
            color: color ?? Colors.yellow,
            strokeWidth: 2.w,
          ),
        ),
      ),
    );
  }

  static bool isEmail(String email) {
    String r = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';

    // r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = RegExp(r, caseSensitive: false);

    return !regExp.hasMatch(email);
  }

  static bool isPhone(String phone) {
    // String r = r'(^(?:[+0]9)?[0-9]{10,12}$)';
    String r = r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$';

    RegExp regExp = RegExp(r);

    return !regExp.hasMatch(phone);
  }

  static double timeInMin(String time) {
    double timeInDouble = 0.0;
    time = time.trim();

    if (time.contains("mins")) {
      timeInDouble = double.parse(time.split(' ').first);
    } else if (time.contains("secs")) {
      timeInDouble = double.parse(time.split(' ').first) * 0.0166667;
    } else if (time.contains("hours")) {
      timeInDouble = double.parse(time.split(' ').first) * 60;
    }
    // log("<<<<<<<<<<<<<<<time#$timeInDouble>>>>>>>>>of#$time>>>>>>");

    return timeInDouble;
  }

  static closeKeyBoard(context) {
    FocusScope.of(context).unfocus();
  }

  static Future<void> openDialer({required String number}) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(uri);
    }
  }

  static Future<void> launchUrl({required String url}) async {
    if (await url_launcher.canLaunchUrl(Uri.parse(url))) {
      await url_launcher.launchUrl(Uri.parse(url));
    }
  }
}
