# devla_request

A Http client request for Dart, which help you zero configuration interceptor with global stage and more cleaner with BaseURL, Logging request, header Authorization set with Bearer and Auto request when Token has expired

## Installing

Add Get to your pubspec.yaml file:
```yaml
dependencies:
  devla_request:
```
Import get in files that it will be used:
```dart
import 'package:devla_request/devla_request.dart';
```

## Using with Getx

- create the new file called index.dart in the <project>/lib/src/controller/index.dart

```dart
class Controller extends GetxController {
  static Controller to = Get.find();
  final Dio _dio = new Dio();

@override
  void onInit() async {
    super.onInit();
    _dio.interceptors.add(DevlaRequest(
      dio: _dio,
      baseUrl: 'https://jsonplaceholder.typicode.com', // enter your baseURL here
    ));
  }
}
```
- add init Getx Controller in the main.dart file
```dart
Future<void> main() async {
  Get.put<Controller>(Controller());
  await GetStorage.init();
  runApp(MyApp());
}
```
- Change the MaterialApp to GetMaterialApp
```dart
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        ...
  }
```

## Usage with devla_request
- add below function to fetchData into the controllers/index.dart
```dart
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
```
- full code in the controllers/index.dart going to be like below.

```dart
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
```

## called function in stateFullWidget 
In this example will use main.dart to called api with controllers/index.dart 
```dart
  Controller _controller = Get.put(Controller());
  List<TodosModel> _listItem = [];

 @override
  void initState() {
    super.initState();
    fetchData();
  }

void fetchData() async {
    var data = await _controller.fetchData();
    var items = json.encode(data);
    _listItem.clear();
    // find more example in lib/src/models/todo.dart 
    _listItem.addAll(todosModelFromJson(items));
    setState(() {});
  }


