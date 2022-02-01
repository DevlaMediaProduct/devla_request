library devla_request;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class DevlaRequest extends InterceptorsWrapper {
  String accessToken;
  String refreshToken;
  final GetStorage box = GetStorage();

  final Dio dio;
  final bool logged;
  final bool refreshTokenOnExpire;
  final String baseUrl;
  final String redirectUrl;
  final String refreshTokenUrl;

  DevlaRequest({
    @required this.dio,
    @required this.baseUrl,
    this.logged = true,
    this.refreshTokenOnExpire = true,
    this.redirectUrl = "/login",
    this.refreshTokenUrl = "/refresh-token",
  });

  @override
  Future onRequest(RequestOptions options) async {
    options.baseUrl = baseUrl;
    if (logged) {
      print(
          "--> ${options.method != null ? options.method.toUpperCase() : 'METHOD'} ${"" + (options.baseUrl ?? "") + (options.path ?? "")}");
    }
    if (box.hasData("token")) {
      accessToken = box.read("token");
      options.headers["Authorization"] = "Bearer $accessToken";
    }
    return options;
  }

  @override
  Future onResponse(response) async {
    return super.onResponse(response);
  }

  @override
  Future onError(DioError dioError) async {
    int responseCode = dioError.response.statusCode;
    if (refreshTokenOnExpire && responseCode == 401 || responseCode == 403) {
      RequestOptions options = dioError.response.request;
      final response = await http.post("$baseUrl/$refreshTokenUrl", headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      });
      final json = jsonDecode(response.body);
      dio.interceptors.requestLock.lock();
      dio.interceptors.responseLock.lock();
      if (json['status']) {
        String token = json['data']['access_token'];
        String newRefreshToken = json['data']['refreshToken'];
        accessToken = token;
        refreshToken = newRefreshToken;
        box.write('token', token);
        box.write('refreshToken', newRefreshToken);
        dio.interceptors.requestLock.unlock();
        dio.interceptors.responseLock.unlock();
        return dio.request(options.path, options: options);
      } else {
        print('onError refresh Token : $response');
        box.remove('token');
        box.remove('refreshToken');
        box.remove('user');
        // if redirectUrl is not null, then redirect to login page
        if (redirectUrl != null) {
          Get.offAllNamed(redirectUrl);
        }
      }
    } else {
      super.onError(dioError);
    }
  }
}
