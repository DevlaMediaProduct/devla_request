import 'package:devla_request/devla_request.dart';
import 'package:get/get.dart' hide Response;
import 'package:dio/dio.dart';

class Controller extends GetxController {
  final Dio _dio = new Dio();

  @override
  void onInit() async {
    super.onInit();
    _dio.interceptors.add(DevlaRequest(
      dio: _dio,
      baseUrl: 'https://jsonplaceholder.typicode.com',
    ));
  }

  fetchData() async {
    try {
      Response response = await _dio.get('/todos/');
      return response.data;
    } catch (e) {
      if (e is DioError) {
        print("error fetchData : ${e.response}");
      }
    }
  }
}
