// import 'dart:ffi';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/material.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: const MyHomePage(title: 'test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var latitude = "";
  var longitude = "";
  var altitude = "";
  var speed = "";
  var address = "";
  var direction1 = "";
  var city = "";
  List<String> tt = [];
  double distanceInMeters1 = 0.0;
  double distanceInMeters2 = 0.0;
  bool isInsideRange1 = false;
  bool isInsideRange2 = false;

  // ignore: unused_field
  StreamSubscription<Position>? _positionStreamSubscription;

  List<Map> targets = [
    {"latitude": 25.1778, "longitude": 121.4439,"news": "50","States":false}, // 目标1纬度和经度
    {"latitude": 25.1757, "longitude": 121.4420,"news": "60","States":false}, // 目标2纬度和经度
  ];

  double fenceRadius = 300; // 圆形围栏半径（以米为单位）

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // 取得目前位置
    _startTrackingPosition(); // 开始追踪位置更新
  }

  @override
  void dispose() {
    _stopTrackingPosition(); // 停止追踪位置更新
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // 取得目前位置
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      _updatePosition(position);
    } catch (e) {
      // ignore: avoid_print
      print('Error getting current location: $e');
    }
  }

  void _startTrackingPosition() {
    // 订阅位置更新的流
    _positionStreamSubscription = Geolocator.getPositionStream().listen(
      (Position position) {
        _updatePosition(position);
      },
      onError: (error) {
        // ignore: avoid_print
        print('Position stream error: $error');
      },
    );
  }

  void _stopTrackingPosition() {
    // 取消位置更新的订阅
    _positionStreamSubscription?.cancel();
  }

  Future<void> _updatePosition(Position position) async {
    tt = [];
    // 根据位置更新相关信息
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    setState(() {
      latitude = position.latitude.toString();
      longitude = position.longitude.toString();
      altitude = position.altitude.toString();
      speed = position.speed.toString();
      address = (placemarks.isNotEmpty ? placemarks[0].toString() : null)!;
      city = (placemarks.isNotEmpty ? placemarks[0].administrativeArea.toString() : null)! ;
      if(city == ""){
        city = (placemarks.isNotEmpty ? placemarks[0].subAdministrativeArea : "")! ;
      }
      
      direction1 = position.heading.toString();
    });

    double heading = position.heading; // 获取heading的值，如果为null则默认为0.0

  // ignore: unused_local_variable
  String direction;
  if (heading >= 45 && heading < 135) {
    direction = '往東';
  } else if (heading >= 135 && heading < 225) {
    direction = '往南';
  } else if (heading >= 225 && heading < 315) {
    direction = '往西';
  } else {
    direction = '往北';
  }

    // 计算当前位置与目标位置的距离
    for (var i = 0; i < targets.length; i++) {
      double targetLatitude = targets[i]["latitude"]!;
      double targetLongitude = targets[i]["longitude"]!;
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLatitude,
        targetLongitude,
      );

      setState(() {
        direction1 = direction;
          if(distanceInMeters <= fenceRadius){
             tt.add(targets[i]["news"]) ;
          }
          targets[i]["States"] = distanceInMeters <= fenceRadius;
      });
    }
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('提示'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              
              Column(children:[
                for (var i = 0; i < 2 ; i++)
                Text(targets[i]["news"]!),
                // Text(tt[tt].toString()),
              ]),
              Text('目标1是否在范围内: ${isInsideRange1 ? '是' : '否'}'), // 显示是否在范围内
              Text('目标2是否在范围内: ${isInsideRange2 ? '是' : '否'}'), // 显示是否在范围内
              const SizedBox(height: 16),
              Text('距离目标1：${distanceInMeters1.toStringAsFixed(2)} 米'), // 显示距离目标1的距离
              Text('距离目标2：${distanceInMeters2.toStringAsFixed(2)} 米'), // 显示距离目标2的距离
            ],
          ),
          actions: [
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('纬度：$latitude'),
            Text('经度：$longitude'),
            Text('速度：$speed'),
            Text('地址：$address'),
            Text('地址：$city'),
            Text('方向：$direction1'),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('0000'),
                if(false)
                const Text('00000000000000'),
              ],
            ),
            Column(children:[
                for (var i = 0; i <  tt.length; i++)
                Text(tt[i])

              ]),
            ElevatedButton(
              onPressed: _showLocationDialog,
              child: const Text('检查位置'),
            ),
          ],
        ),
      ),
    );
  }
}
