library devla_request;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class DevlaRequest extends InterceptorsWrapper {
  // init dio with new instance variable
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
    // add baseUrl before sending a request
    options.baseUrl = baseUrl;
    // check if user is logged
    if (logged) {
      // print log every request
      print(
          "--> ${options.method != null ? options.method.toUpperCase() : 'METHOD'} ${"" + (options.baseUrl ?? "") + (options.path ?? "")}");
    }
    // check if user is logged should be contain box has token
    if (box.hasData("token")) {
      // get token from box & assign to header
      accessToken = box.read("token");
      // add token to header with bearer
      options.headers["Authorization"] = "Bearer $accessToken";
    }
    // return request
    return options;
  }

  @override
  Future onResponse(response) async {
    // check every respoonse from server in here
    return super.onResponse(response);
  }

  @override
  Future onError(DioError dioError) async {
    // check every error in here
    // if error is 401 and refresh token is true
    int responseCode = dioError.response.statusCode;
    if (refreshTokenOnExpire && responseCode == 401 || responseCode == 403) {
      // get refresh token from box
      RequestOptions options = dioError.response.request;
      // requst refresh token from server with refresh token url with http method post
      final response = await http.post("$baseUrl/$refreshTokenUrl", headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      });
      // if response is success
      final json = jsonDecode(response.body);
      // lock every request before sending a new request with new token
      dio.interceptors.requestLock.lock();
      dio.interceptors.responseLock.lock();
      // check reqest is success
      if (json['status']) {
        // get new token from response
        String token = json['data']['access_token'];
        // get refresh token from response
        String newRefreshToken = json['data']['refreshToken'];
        // assign new token to access token & refresh token variable
        accessToken = token;
        refreshToken = newRefreshToken;
        // add new token to box
        box.write('token', token);
        // add new refresh token to box
        box.write('refreshToken', newRefreshToken);
        // unlock every request after sending a new request with new token
        dio.interceptors.requestLock.unlock();
        dio.interceptors.responseLock.unlock();
        // return request with new token that still pending
        return dio.request(options.path, options: options);
      } else {
        // if request is not success
        print('onError refresh Token : $response');
        // unlock every request after sending a new request with new token
        dio.interceptors.requestLock.unlock();
        dio.interceptors.responseLock.unlock();
        // remove token from box
        box.remove('token');
        // remove refresh token from box
        box.remove('refreshToken');
        box.remove('user');
        // redirect to login page
        // if redirectUrl is not null, then redirect to login page
        if (redirectUrl != null) {
          Get.offAllNamed(redirectUrl);
        }
      }
    } else {
      // if error is not 401 or 403
      super.onError(dioError);
    }
  }
}
