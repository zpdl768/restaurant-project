import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  
  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(37.551214, 126.924432), // 홍익대학교 근처
    zoom: 17.0, // 초기 줌 레벨
  );

  double currentZoomLevel = 17.0; // 현재 줌 레벨 상태 관리
  Set<Marker> markers = {}; // 지도에 표시할 마커들
  Map<String, double> crowdHues = {
  "green": 120.0, // 초록색
  "yellow": 60.0, // 밝은 노란색
  "orange": 39.0, // 밝은 주황색 (HSV 기준)
  "red": 0.0,     // 빨간색
  "gray": 0.0,    // 회색은 hue 무시 (혹은 기본값)
  };
  
  Map<String, Color> crowdColors = {
    "green": Colors.green,
    "yellow":const Color.fromARGB(255, 241, 217, 0),
    //"yellow":Colors.yellow,
    //"yellow": const Color.fromARGB(255, 255, 235, 59), // 진한 노란색
    "orange":Colors.orangeAccent,
    //"orange": const Color.fromARGB(255, 237, 154, 0), // 진한 주황색
    "red": Colors.red,
    "gray": Colors.grey,
  };
  

  @override
  void initState() {
    super.initState();
    _fetchData(); // 초기 데이터 요청
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/restaurants'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _addMarkers(data);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }
  /*
  void _addMarkers(List<dynamic> data) {
    setState(() {
      markers.clear();
      for (var item in data) {
        final LatLng position = _addressToLatLng(item['restaurant_address']);
        final String name = item['restaurant_name'];
        final String crowdLevel = item['crowd_level'];

        markers.add(
          Marker(
            markerId: MarkerId(name),
            position: position,
            infoWindow: InfoWindow(title: name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              
            _colorToHue(crowdColors[crowdLevel] ?? Colors.white),
            ),
            onTap: () {
              _showBottomSheet(context, name, item['restaurant_address'], crowdLevel);
            },
          ),
        );
      }
    });
  }
  */

  void _addMarkers(List<dynamic> data) {
  setState(() {
    markers.clear();
    for (var item in data) {
      final LatLng position = _addressToLatLng(item['restaurant_address']);
      final String name = item['restaurant_name'];
      final String crowdLevel = item['crowd_level'];

      // 메뉴 데이터를 안전하게 가져오기
      final List<String> menus = [
        item['menu1'] ?? "메뉴 정보 없음1",
        item['menu2'] ?? "메뉴 정보 없음2",
        item['menu3'] ?? "메뉴 정보 없음",
        item['menu4'] ?? "메뉴 정보 없음",
        item['menu5'] ?? "메뉴 정보 없음",
      ];

      /*
      final String menu1 = item['menu1'];
      final String menu2 = item['menu2'];
      final String menu3 = item['menu3'];
      final String menu4 = item['menu4'];
      final String menu5 = item['menu5'];
      */

      markers.add(
        Marker(
          markerId: MarkerId(name),
          position: position,
          infoWindow: InfoWindow(title: name),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _colorToHue(crowdColors[crowdLevel] ?? Colors.white),
          ),
          onTap: () {
            _showBottomSheet(
              context,
              name,
              item['restaurant_address'],
              crowdLevel,
              menus, // 안전하게 처리된 메뉴 리스트 전달
              
            );
          },
        ),
      );
    }
  });
}

  LatLng _addressToLatLng(String address) {
    Map<String, LatLng> mockData = {
      "서울특별시 마포구 상수동": LatLng(37.551214, 126.924432),
      "서울특별시 마포구 연남동": LatLng(37.566, 126.923),
      "서울특별시 마포구 와우산로 94": LatLng(37.550100, 126.924432),
      //"서울 마포구 독막로19길 19 1층": LatLng(37.548430, 126.924620),
      "서울 마포구 와우산로 51-6": LatLng(37.54928986921307, 126.92268043756485), // 칸다소바
      "서울 마포구 와우산로 51-9 1층": LatLng(37.5492154404851, 126.92246988415718), // 김덕후의곱창조
      "서울 마포구 와우산로15길 15": LatLng(37.54961841799544, 126.92235186696053), // 윤씨밀방
      "서울 마포구 와우산로15길 30": LatLng(37.54924042728065, 126.92160554230213), // 제순식당
      "서울 마포구 와우산로13길 9 골목집": LatLng(37.54961841799544, 126.92261338233948), // 골목집
      "서울 마포구 와우산로15길 28 1층": LatLng(37.549340906012134, 126.92172557115555), // 후타츠 홍대점
    };
    return mockData[address] ?? const LatLng(37.538214, 126.924432);
  }

  double _colorToHue(Color color) {
    return HSVColor.fromColor(color).hue;
  }

  void _showBottomSheet(BuildContext context, String name, String address, String crowdLevel, List<String> menus) {
    // 메뉴의 초기 수량 상태를 관리하기 위한 Map
    Map<String, int> menuQuantities = {
      for (var menu in menus) menu: 0, // 각 메뉴의 초기 수량을 0으로 설정
    };
    int headcount = 1; // 기본값 1

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      //builder: (context) {
      builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {

        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 1.0, // 정보창 높이 설정
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // 닫기 버튼
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.grey[200],
                    ),
                    child: const Icon(Icons.close, color: Colors.black),
                  ),
                ],
              ),
              /*const SizedBox(height: 10),
              Text(
                "주소: $address",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),*/
              Row(
                children: [
                  Text(
                    "혼잡도: $crowdLevel",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: crowdColors[crowdLevel] ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const Divider(height: 10),
              const SizedBox(height: 10), // 혼잡도와 메뉴 사이 간격 내가 추가ㅎㅎ
              
              
              // 메뉴 목록 추가
              const Text(
                "메뉴",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),

              /*for (var menu in menus)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(menu, style: const TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (menuQuantities[menu]! > 1) menuQuantities[menu] = menuQuantities[menu]! - 1;
                            });
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        Text('${menuQuantities[menu]}'),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              menuQuantities[menu] = menuQuantities[menu]! + 1;
                            });
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 0), // 각 메뉴 간 간격 설정
                  ],
                ),
                */
                for (var menu in menus)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          menu,
                          style: const TextStyle(fontSize: 20),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (menuQuantities[menu] != null && menuQuantities[menu]! > 0) {
                                  menuQuantities[menu] = menuQuantities[menu]! - 1;
                                }
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                border: Border.all(color: Colors.black, width: 1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  "-",
                                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                          /*

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '${menuQuantities[menu] ?? 0}',
                              style: const TextStyle(fontSize: 20), // 예약 인원과 동일한 스타일 적용
                            ),
                          ),
                          */
                          const SizedBox(width: 8), // 버튼과 수량 텍스트 사이 간격
                          SizedBox(
                            width: 40, // 수량 텍스트의 너비를 40으로 고정
                            child: Center(
                              child: Text(
                                '${menuQuantities[menu]}', // 수량 텍스트
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8), // 수량 텍스트와 '+' 버튼 사이 간격

                          GestureDetector(
                            onTap: () {
                              setState(() {
                                // Null 확인 후 값 증가
                                if (menuQuantities[menu] != null) {
                                  menuQuantities[menu] = menuQuantities[menu]! + 1;
                                }
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                border: Border.all(color: Colors.black, width: 1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  "+",
                                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              


              const SizedBox(height: 5), // 메뉴와 예약 인원 사이 간격


              // 예약 인원 추가
              const Text(
                "예약 인원",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 5),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: const Text(
                      "총 인원",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (headcount > 1) {
                              headcount--;
                            }
                          });
                        },
                      borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            border: Border.all(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              "-",
                              style: TextStyle(color: Colors.black, fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                      /*

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('$headcount', style: const TextStyle(fontSize: 20)),
                      ),
                      */
                      const SizedBox(width: 8), // 버튼과 숫자 텍스트 사이 간격
                      SizedBox(
                        width: 40, // 고정된 너비 설정
                        child: Center(
                          child: Text(
                            '$headcount', // 총 인원 숫자
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8), // 버튼과 숫자 텍스트 사이 간격


                      InkWell(
                        onTap: () {
                          setState(() {
                            headcount++;
                          });
                        },
                        borderRadius: BorderRadius.circular(4),
                      /*
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            headcount++;
                          });
                        },
                        */
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            border: Border.all(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              "+",
                              style: TextStyle(color: Colors.black, fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              /*
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (headcount > 1) headcount--;
                      });
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$headcount', style: const TextStyle(fontSize: 18)),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        headcount++;
                      });
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              */
              
              const Spacer(),

              const Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final selectedMenus = menuQuantities.entries
                        .where((entry) => entry.value > 0)
                        .map((entry) => {'menu': entry.key, 'quantity': entry.value})
                        .toList();

                    final orderData = {
                      'user_ID': 'user123',
                      'restaurant_ID': '10',
                      'menus': selectedMenus,
                      'headcount': headcount,
                    };

                    final response = await http.post(
                      Uri.parse('http://localhost:3000/order'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode(orderData),
                    );

                    if (response.statusCode == 200) {
                      print("Order sent successfully");

                      // 주문이 전송되었음을 알리는 Overlay 표시
                      final overlay = Overlay.of(context);
                      final overlayEntry = OverlayEntry(
                        builder: (context) => Positioned(
                          top: MediaQuery.of(context).size.height / 2 - 50,
                          left: MediaQuery.of(context).size.width / 2 - 100,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: 200,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "주문이 전송되었습니다!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );

                      overlay.insert(overlayEntry);

                      // 3초 후 Overlay 제거
                      await Future.delayed(const Duration(seconds: 3));
                      overlayEntry.remove();


                      // 30초 후 서버 상태 확인
        await Future.delayed(const Duration(seconds: 30));
        final statusResponse = await http.get(
          Uri.parse('http://localhost:3000/reservation_status'),
        );

        if (statusResponse.statusCode == 200) {
          final status = json.decode(statusResponse.body)['status'];

          if (status == 'accepted') {
            // 예약 상태에 따라 메시지 표시
            final statusOverlay = OverlayEntry(
              builder: (context) => Positioned(
                top: MediaQuery.of(context).size.height / 2 - 50,
                left: MediaQuery.of(context).size.width / 2 - 100,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 250,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "주문이 수락되었습니다.\n주문하신 음식을 조리합니다😋",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );

            overlay.insert(statusOverlay);

            // 3초 후 Overlay 제거
            await Future.delayed(const Duration(seconds: 3));
            statusOverlay.remove();
          }
        }








                      Navigator.pop(context);
                    } else {
                      print("Failed to send order");
                      print("Response body: ${response.body}");
                    }







                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: const Text("주문 전송", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            
            ],
          ),
        );
      }, //
      ); //
      }, //  
      
    );
  }

  void _zoomIn() async {
    final controller = await _controller.future;
    setState(() {
      currentZoomLevel += 1;
      controller.animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
    });
  }

  void _zoomOut() async {
    final controller = await _controller.future;
    setState(() {
      currentZoomLevel -= 1;
      controller.animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 지도
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: initialCameraPosition,
            markers: markers,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            }.toSet(),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false, // Google 로고 제거
          ),
          // 검색창
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, // 매직아일랜드 영역 고려
            left: 16,
            right: 16,
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.text,
              textAlignVertical: TextAlignVertical.center, // 힌트 텍스트 가운데 정렬
              decoration: InputDecoration(
                hintText: "검색",
                hintStyle: const TextStyle(color: Colors.grey), // 연한 글자 색상
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // 새로고침 및 확대/축소 버튼
          Positioned(
            right: 10,
            top: MediaQuery.of(context).padding.top + 80, // 검색창과 겹치지 않도록 아래로 이동
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _fetchData,
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _zoomIn,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "+",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _zoomOut,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "-",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}









/*
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  
  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(37.551214, 126.924432), // 홍익대학교 근처
    zoom: 17.0, // 초기 줌 레벨
  );

  double currentZoomLevel = 17.0; // 현재 줌 레벨 상태 관리
  Set<Marker> markers = {}; // 지도에 표시할 마커들
  Map<String, double> crowdHues = {
  "green": 120.0, // 초록색
  "yellow": 60.0, // 밝은 노란색
  "orange": 39.0, // 밝은 주황색 (HSV 기준)
  "red": 0.0,     // 빨간색
  "gray": 0.0,    // 회색은 hue 무시 (혹은 기본값)
  };
  
  Map<String, Color> crowdColors = {
    "green": Colors.green,
    "yellow":const Color.fromARGB(255, 241, 217, 0),
    //"yellow":Colors.yellow,
    //"yellow": const Color.fromARGB(255, 255, 235, 59), // 진한 노란색
    "orange":Colors.orangeAccent,
    //"orange": const Color.fromARGB(255, 237, 154, 0), // 진한 주황색
    "red": Colors.red,
    "gray": Colors.grey,
  };
  

  @override
  void initState() {
    super.initState();
    _fetchData(); // 초기 데이터 요청
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/restaurants'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _addMarkers(data);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }
  /*
  void _addMarkers(List<dynamic> data) {
    setState(() {
      markers.clear();
      for (var item in data) {
        final LatLng position = _addressToLatLng(item['restaurant_address']);
        final String name = item['restaurant_name'];
        final String crowdLevel = item['crowd_level'];

        markers.add(
          Marker(
            markerId: MarkerId(name),
            position: position,
            infoWindow: InfoWindow(title: name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              
            _colorToHue(crowdColors[crowdLevel] ?? Colors.white),
            ),
            onTap: () {
              _showBottomSheet(context, name, item['restaurant_address'], crowdLevel);
            },
          ),
        );
      }
    });
  }
  */

  void _addMarkers(List<dynamic> data) {
  setState(() {
    markers.clear();
    for (var item in data) {
      final LatLng position = _addressToLatLng(item['restaurant_address']);
      final String name = item['restaurant_name'];
      final String crowdLevel = item['crowd_level'];

      // 메뉴 데이터를 안전하게 가져오기
      final List<String> menus = [
        item['menu1'] ?? "메뉴 정보 없음1",
        item['menu2'] ?? "메뉴 정보 없음2",
        item['menu3'] ?? "메뉴 정보 없음",
        item['menu4'] ?? "메뉴 정보 없음",
        item['menu5'] ?? "메뉴 정보 없음",
      ];

      /*
      final String menu1 = item['menu1'];
      final String menu2 = item['menu2'];
      final String menu3 = item['menu3'];
      final String menu4 = item['menu4'];
      final String menu5 = item['menu5'];
      */

      markers.add(
        Marker(
          markerId: MarkerId(name),
          position: position,
          infoWindow: InfoWindow(title: name),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _colorToHue(crowdColors[crowdLevel] ?? Colors.white),
          ),
          onTap: () {
            _showBottomSheet(
              context,
              name,
              item['restaurant_address'],
              crowdLevel,
              menus, // 안전하게 처리된 메뉴 리스트 전달
              
            );
          },
        ),
      );
    }
  });
}

  LatLng _addressToLatLng(String address) {
    Map<String, LatLng> mockData = {
      "서울특별시 마포구 상수동": LatLng(37.551214, 126.924432),
      "서울특별시 마포구 연남동": LatLng(37.566, 126.923),
      "서울특별시 마포구 와우산로 94": LatLng(37.550100, 126.924432),
      //"서울 마포구 독막로19길 19 1층": LatLng(37.548430, 126.924620),
      "서울 마포구 와우산로 51-6": LatLng(37.54928986921307, 126.92268043756485), // 칸다소바
      "서울 마포구 와우산로 51-9 1층": LatLng(37.5492154404851, 126.92246988415718), // 김덕후의곱창조
      "서울 마포구 와우산로15길 15": LatLng(37.54961841799544, 126.92235186696053), // 윤씨밀방
      "서울 마포구 와우산로15길 30": LatLng(37.54924042728065, 126.92160554230213), // 제순식당
      "서울 마포구 와우산로13길 9 골목집": LatLng(37.54961841799544, 126.92261338233948), // 골목집
      "서울 마포구 와우산로15길 28 1층": LatLng(37.549340906012134, 126.92172557115555), // 후타츠 홍대점
    };
    return mockData[address] ?? const LatLng(37.538214, 126.924432);
  }

  double _colorToHue(Color color) {
    return HSVColor.fromColor(color).hue;
  }

  void _showBottomSheet(BuildContext context, String name, String address, String crowdLevel, List<String> menus) {
    // 메뉴의 초기 수량 상태를 관리하기 위한 Map
    Map<String, int> menuQuantities = {
      for (var menu in menus) menu: 0, // 각 메뉴의 초기 수량을 0으로 설정
    };
    int headcount = 1; // 기본값 1

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      //builder: (context) {
      builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {

        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 1.0, // 정보창 높이 설정
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // 닫기 버튼
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.grey[200],
                    ),
                    child: const Icon(Icons.close, color: Colors.black),
                  ),
                ],
              ),
              /*const SizedBox(height: 10),
              Text(
                "주소: $address",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),*/
              Row(
                children: [
                  Text(
                    "혼잡도: $crowdLevel",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: crowdColors[crowdLevel] ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const Divider(height: 10),
              const SizedBox(height: 10), // 혼잡도와 메뉴 사이 간격 내가 추가ㅎㅎ
              
              
              // 메뉴 목록 추가
              const Text(
                "메뉴",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),

              /*for (var menu in menus)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(menu, style: const TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (menuQuantities[menu]! > 1) menuQuantities[menu] = menuQuantities[menu]! - 1;
                            });
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        Text('${menuQuantities[menu]}'),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              menuQuantities[menu] = menuQuantities[menu]! + 1;
                            });
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 0), // 각 메뉴 간 간격 설정
                  ],
                ),
                */
                for (var menu in menus)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          menu,
                          style: const TextStyle(fontSize: 20),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (menuQuantities[menu] != null && menuQuantities[menu]! > 0) {
                                  menuQuantities[menu] = menuQuantities[menu]! - 1;
                                }
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                border: Border.all(color: Colors.black, width: 1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  "-",
                                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                          /*

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '${menuQuantities[menu] ?? 0}',
                              style: const TextStyle(fontSize: 20), // 예약 인원과 동일한 스타일 적용
                            ),
                          ),
                          */
                          const SizedBox(width: 8), // 버튼과 수량 텍스트 사이 간격
                          SizedBox(
                            width: 40, // 수량 텍스트의 너비를 40으로 고정
                            child: Center(
                              child: Text(
                                '${menuQuantities[menu]}', // 수량 텍스트
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8), // 수량 텍스트와 '+' 버튼 사이 간격

                          GestureDetector(
                            onTap: () {
                              setState(() {
                                // Null 확인 후 값 증가
                                if (menuQuantities[menu] != null) {
                                  menuQuantities[menu] = menuQuantities[menu]! + 1;
                                }
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                border: Border.all(color: Colors.black, width: 1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  "+",
                                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              


              const SizedBox(height: 5), // 메뉴와 예약 인원 사이 간격


              // 예약 인원 추가
              const Text(
                "예약 인원",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 5),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: const Text(
                      "총 인원",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (headcount > 1) {
                              headcount--;
                            }
                          });
                        },
                      borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            border: Border.all(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              "-",
                              style: TextStyle(color: Colors.black, fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                      /*

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('$headcount', style: const TextStyle(fontSize: 20)),
                      ),
                      */
                      const SizedBox(width: 8), // 버튼과 숫자 텍스트 사이 간격
                      SizedBox(
                        width: 40, // 고정된 너비 설정
                        child: Center(
                          child: Text(
                            '$headcount', // 총 인원 숫자
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8), // 버튼과 숫자 텍스트 사이 간격


                      InkWell(
                        onTap: () {
                          setState(() {
                            headcount++;
                          });
                        },
                        borderRadius: BorderRadius.circular(4),
                      /*
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            headcount++;
                          });
                        },
                        */
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            border: Border.all(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              "+",
                              style: TextStyle(color: Colors.black, fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              /*
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (headcount > 1) headcount--;
                      });
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$headcount', style: const TextStyle(fontSize: 18)),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        headcount++;
                      });
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              */
              
              const Spacer(),

              const Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final selectedMenus = menuQuantities.entries
                        .where((entry) => entry.value > 0)
                        .map((entry) => {'menu': entry.key, 'quantity': entry.value})
                        .toList();

                    final orderData = {
                      'user_ID': 'user123',
                      'restaurant_ID': '10',
                      'menus': selectedMenus,
                      'headcount': headcount,
                    };

                    final response = await http.post(
                      Uri.parse('http://localhost:3000/order'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode(orderData),
                    );

                    if (response.statusCode == 200) {
                      print("Order sent successfully");

                      // 주문이 전송되었음을 알리는 Overlay 표시
                      final overlay = Overlay.of(context);
                      final overlayEntry = OverlayEntry(
                        builder: (context) => Positioned(
                          top: MediaQuery.of(context).size.height / 2 - 50,
                          left: MediaQuery.of(context).size.width / 2 - 100,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: 200,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "주문이 전송되었습니다!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );

                      overlay.insert(overlayEntry);

                      // 3초 후 Overlay 제거
                      await Future.delayed(const Duration(seconds: 3));
                      overlayEntry.remove();


                      Navigator.pop(context);
                    } else {
                      print("Failed to send order");
                      print("Response body: ${response.body}");
                    }



                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: const Text("주문 전송", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            
            ],
          ),
        );
      }, //
      ); //
      }, //  
      
    );
  }

  void _zoomIn() async {
    final controller = await _controller.future;
    setState(() {
      currentZoomLevel += 1;
      controller.animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
    });
  }

  void _zoomOut() async {
    final controller = await _controller.future;
    setState(() {
      currentZoomLevel -= 1;
      controller.animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 지도
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: initialCameraPosition,
            markers: markers,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            }.toSet(),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false, // Google 로고 제거
          ),
          // 검색창
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, // 매직아일랜드 영역 고려
            left: 16,
            right: 16,
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.text,
              textAlignVertical: TextAlignVertical.center, // 힌트 텍스트 가운데 정렬
              decoration: InputDecoration(
                hintText: "검색",
                hintStyle: const TextStyle(color: Colors.grey), // 연한 글자 색상
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // 새로고침 및 확대/축소 버튼
          Positioned(
            right: 10,
            top: MediaQuery.of(context).padding.top + 80, // 검색창과 겹치지 않도록 아래로 이동
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _fetchData,
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _zoomIn,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "+",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _zoomOut,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "-",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
*/









/*

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  
  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(37.551214, 126.924432), // 홍익대학교 근처
    zoom: 17.0, // 초기 줌 레벨
  );

  double currentZoomLevel = 17.0; // 현재 줌 레벨 상태 관리
  Set<Marker> markers = {}; // 지도에 표시할 마커들
  Map<String, double> crowdHues = {
  "green": 120.0, // 초록색
  "yellow": 60.0, // 밝은 노란색
  "orange": 39.0, // 밝은 주황색 (HSV 기준)
  "red": 0.0,     // 빨간색
  "gray": 0.0,    // 회색은 hue 무시 (혹은 기본값)
  };
  
  Map<String, Color> crowdColors = {
    "green": Colors.green,
    "yellow":const Color.fromARGB(255, 241, 217, 0),
    //"yellow":Colors.yellow,
    //"yellow": const Color.fromARGB(255, 255, 235, 59), // 진한 노란색
    "orange":Colors.orangeAccent,
    //"orange": const Color.fromARGB(255, 237, 154, 0), // 진한 주황색
    "red": Colors.red,
    "gray": Colors.grey,
  };
  

  @override
  void initState() {
    super.initState();
    _fetchData(); // 초기 데이터 요청
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/restaurants'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _addMarkers(data);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }
  /*
  void _addMarkers(List<dynamic> data) {
    setState(() {
      markers.clear();
      for (var item in data) {
        final LatLng position = _addressToLatLng(item['restaurant_address']);
        final String name = item['restaurant_name'];
        final String crowdLevel = item['crowd_level'];

        markers.add(
          Marker(
            markerId: MarkerId(name),
            position: position,
            infoWindow: InfoWindow(title: name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              
            _colorToHue(crowdColors[crowdLevel] ?? Colors.white),
            ),
            onTap: () {
              _showBottomSheet(context, name, item['restaurant_address'], crowdLevel);
            },
          ),
        );
      }
    });
  }
  */

  void _addMarkers(List<dynamic> data) {
  setState(() {
    markers.clear();
    for (var item in data) {
      final LatLng position = _addressToLatLng(item['restaurant_address']);
      final String name = item['restaurant_name'];
      final String crowdLevel = item['crowd_level'];

      // 메뉴 데이터를 안전하게 가져오기
      final List<String> menus = [
        item['menu1'] ?? "메뉴 정보 없음1",
        item['menu2'] ?? "메뉴 정보 없음2",
        item['menu3'] ?? "메뉴 정보 없음",
        item['menu4'] ?? "메뉴 정보 없음",
        item['menu5'] ?? "메뉴 정보 없음",
      ];

      /*
      final String menu1 = item['menu1'];
      final String menu2 = item['menu2'];
      final String menu3 = item['menu3'];
      final String menu4 = item['menu4'];
      final String menu5 = item['menu5'];
      */

      markers.add(
        Marker(
          markerId: MarkerId(name),
          position: position,
          infoWindow: InfoWindow(title: name),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _colorToHue(crowdColors[crowdLevel] ?? Colors.white),
          ),
          onTap: () {
            _showBottomSheet(
              context,
              name,
              item['restaurant_address'],
              crowdLevel,
              menus, // 안전하게 처리된 메뉴 리스트 전달
              
            );
          },
        ),
      );
    }
  });
}

  LatLng _addressToLatLng(String address) {
    Map<String, LatLng> mockData = {
      "서울특별시 마포구 상수동": LatLng(37.551214, 126.924432),
      "서울특별시 마포구 연남동": LatLng(37.566, 126.923),
      "서울특별시 마포구 와우산로 94": LatLng(37.550100, 126.924432),
      //"서울 마포구 독막로19길 19 1층": LatLng(37.548430, 126.924620),
      "서울 마포구 와우산로 51-6": LatLng(37.54928986921307, 126.92268043756485), // 칸다소바
      "서울 마포구 와우산로 51-9 1층": LatLng(37.5492154404851, 126.92246988415718), // 김덕후의곱창조
      "서울 마포구 와우산로15길 15": LatLng(37.54961841799544, 126.92235186696053), // 윤씨밀방
      "서울 마포구 와우산로15길 30": LatLng(37.54924042728065, 126.92160554230213), // 제순식당
      "서울 마포구 와우산로13길 9 골목집": LatLng(37.54961841799544, 126.92261338233948), // 골목집
      "서울 마포구 와우산로15길 28 1층": LatLng(37.549340906012134, 126.92172557115555), // 후타츠 홍대점
    };
    return mockData[address] ?? const LatLng(37.538214, 126.924432);
  }

  double _colorToHue(Color color) {
    return HSVColor.fromColor(color).hue;
  }

  void _showBottomSheet(BuildContext context, String name, String address, String crowdLevel, List<String> menus) {
    // 메뉴의 초기 수량 상태를 관리하기 위한 Map
    Map<String, int> menuQuantities = {
      for (var menu in menus) menu: 0, // 각 메뉴의 초기 수량을 0으로 설정
    };
    int headcount = 1; // 기본값 1

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      //builder: (context) {
      builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {

        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 1.0, // 정보창 높이 설정
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // 닫기 버튼
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.grey[200],
                    ),
                    child: const Icon(Icons.close, color: Colors.black),
                  ),
                ],
              ),
              /*const SizedBox(height: 10),
              Text(
                "주소: $address",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),*/
              Row(
                children: [
                  Text(
                    "혼잡도: $crowdLevel",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: crowdColors[crowdLevel] ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const Divider(height: 10),
              const SizedBox(height: 10), // 혼잡도와 메뉴 사이 간격 내가 추가ㅎㅎ
              
              
              // 메뉴 목록 추가
              const Text(
                "메뉴",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),

              /*for (var menu in menus)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(menu, style: const TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (menuQuantities[menu]! > 1) menuQuantities[menu] = menuQuantities[menu]! - 1;
                            });
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        Text('${menuQuantities[menu]}'),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              menuQuantities[menu] = menuQuantities[menu]! + 1;
                            });
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 0), // 각 메뉴 간 간격 설정
                  ],
                ),
                */
                for (var menu in menus)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          menu,
                          style: const TextStyle(fontSize: 20),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (menuQuantities[menu] != null && menuQuantities[menu]! > 0) {
                                  menuQuantities[menu] = menuQuantities[menu]! - 1;
                                }
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                border: Border.all(color: Colors.black, width: 1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  "-",
                                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                          /*

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '${menuQuantities[menu] ?? 0}',
                              style: const TextStyle(fontSize: 20), // 예약 인원과 동일한 스타일 적용
                            ),
                          ),
                          */
                          const SizedBox(width: 8), // 버튼과 수량 텍스트 사이 간격
                          SizedBox(
                            width: 40, // 수량 텍스트의 너비를 40으로 고정
                            child: Center(
                              child: Text(
                                '${menuQuantities[menu]}', // 수량 텍스트
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8), // 수량 텍스트와 '+' 버튼 사이 간격

                          GestureDetector(
                            onTap: () {
                              setState(() {
                                // Null 확인 후 값 증가
                                if (menuQuantities[menu] != null) {
                                  menuQuantities[menu] = menuQuantities[menu]! + 1;
                                }
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                border: Border.all(color: Colors.black, width: 1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  "+",
                                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              


              const SizedBox(height: 5), // 메뉴와 예약 인원 사이 간격


              // 예약 인원 추가
              const Text(
                "예약 인원",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 5),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: const Text(
                      "총 인원",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (headcount > 1) {
                              headcount--;
                            }
                          });
                        },
                      borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            border: Border.all(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              "-",
                              style: TextStyle(color: Colors.black, fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                      /*

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('$headcount', style: const TextStyle(fontSize: 20)),
                      ),
                      */
                      const SizedBox(width: 8), // 버튼과 숫자 텍스트 사이 간격
                      SizedBox(
                        width: 40, // 고정된 너비 설정
                        child: Center(
                          child: Text(
                            '$headcount', // 총 인원 숫자
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8), // 버튼과 숫자 텍스트 사이 간격


                      InkWell(
                        onTap: () {
                          setState(() {
                            headcount++;
                          });
                        },
                        borderRadius: BorderRadius.circular(4),
                      /*
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            headcount++;
                          });
                        },
                        */
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            border: Border.all(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              "+",
                              style: TextStyle(color: Colors.black, fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              /*
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (headcount > 1) headcount--;
                      });
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$headcount', style: const TextStyle(fontSize: 18)),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        headcount++;
                      });
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              */
              
              const Spacer(),

              const Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final selectedMenus = menuQuantities.entries
                        .where((entry) => entry.value > 0)
                        .map((entry) => {'menu': entry.key, 'quantity': entry.value})
                        .toList();

                    final orderData = {
                      'user_ID': 'user123',
                      'restaurant_ID': '10',
                      'menus': selectedMenus,
                      'headcount': headcount,
                    };

                    final response = await http.post(
                      Uri.parse('http://localhost:3000/order'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode(orderData),
                    );

                    if (response.statusCode == 200) {
                      print("Order sent successfully");

                      // 주문이 전송되었음을 알리는 Overlay 표시
                      final overlay = Overlay.of(context);
                      final overlayEntry = OverlayEntry(
                        builder: (context) => Positioned(
                          top: MediaQuery.of(context).size.height / 2 - 50,
                          left: MediaQuery.of(context).size.width / 2 - 100,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: 200,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "주문이 전송되었습니다!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );

                      overlay.insert(overlayEntry);

                      // 3초 후 Overlay 제거
                      await Future.delayed(const Duration(seconds: 3));
                      overlayEntry.remove();


                      Navigator.pop(context);
                    } else {
                      print("Failed to send order");
                      print("Response body: ${response.body}");
                    }



                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: const Text("주문 전송", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            
              /*
              Padding(
                padding: const EdgeInsets.only(bottom: 10), // 버튼 위로 살짝 이동
                child: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await Future.delayed(const Duration(milliseconds: 200)); // 딜레이
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[300], // 기본 색상
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    child: const Text(
                      "주문 전송",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),*/
            ],
          ),
        );
      }, //
      ); //
      }, //  
      
    );
  }

  void _zoomIn() async {
    final controller = await _controller.future;
    setState(() {
      currentZoomLevel += 1;
      controller.animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
    });
  }

  void _zoomOut() async {
    final controller = await _controller.future;
    setState(() {
      currentZoomLevel -= 1;
      controller.animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 지도
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: initialCameraPosition,
            markers: markers,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            }.toSet(),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false, // Google 로고 제거
          ),
          // 검색창
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, // 매직아일랜드 영역 고려
            left: 16,
            right: 16,
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.text,
              textAlignVertical: TextAlignVertical.center, // 힌트 텍스트 가운데 정렬
              decoration: InputDecoration(
                hintText: "검색",
                hintStyle: const TextStyle(color: Colors.grey), // 연한 글자 색상
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // 새로고침 및 확대/축소 버튼
          Positioned(
            right: 10,
            top: MediaQuery.of(context).padding.top + 80, // 검색창과 겹치지 않도록 아래로 이동
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _fetchData,
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _zoomIn,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "+",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _zoomOut,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "-",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
*/












/*
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();

  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(37.551214, 126.924432), // 홍익대학교 근처
    zoom: 17.0, // 초기 줌 레벨
  );

  double currentZoomLevel = 17.0; // 현재 줌 레벨 상태 관리
  Set<Marker> markers = {}; // 지도에 표시할 마커들
  Map<String, double> crowdHues = {
  "green": 120.0, // 초록색
  "yellow": 60.0, // 밝은 노란색
  "orange": 39.0, // 밝은 주황색 (HSV 기준)
  "red": 0.0,     // 빨간색
  "gray": 0.0,    // 회색은 hue 무시 (혹은 기본값)
  };
  
  Map<String, Color> crowdColors = {
    "green": Colors.green,
    "yellow":const Color.fromARGB(255, 241, 217, 0),
    //"yellow":Colors.yellow,
    //"yellow": const Color.fromARGB(255, 255, 235, 59), // 진한 노란색
    "orange":Colors.orangeAccent,
    //"orange": const Color.fromARGB(255, 237, 154, 0), // 진한 주황색
    "red": Colors.red,
    "gray": Colors.grey,
  };
  

  @override
  void initState() {
    super.initState();
    _fetchData(); // 초기 데이터 요청
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/restaurants'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _addMarkers(data);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }
  /*
  void _addMarkers(List<dynamic> data) {
    setState(() {
      markers.clear();
      for (var item in data) {
        final LatLng position = _addressToLatLng(item['restaurant_address']);
        final String name = item['restaurant_name'];
        final String crowdLevel = item['crowd_level'];

        markers.add(
          Marker(
            markerId: MarkerId(name),
            position: position,
            infoWindow: InfoWindow(title: name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              
            _colorToHue(crowdColors[crowdLevel] ?? Colors.white),
            ),
            onTap: () {
              _showBottomSheet(context, name, item['restaurant_address'], crowdLevel);
            },
          ),
        );
      }
    });
  }
  */

  void _addMarkers(List<dynamic> data) {
  setState(() {
    markers.clear();
    for (var item in data) {
      final LatLng position = _addressToLatLng(item['restaurant_address']);
      final String name = item['restaurant_name'];
      final String crowdLevel = item['crowd_level'];

      // 메뉴 데이터를 안전하게 가져오기
      final List<String> menus = [
        item['menu1'] ?? "메뉴 정보 없음1",
        item['menu2'] ?? "메뉴 정보 없음2",
        item['menu3'] ?? "메뉴 정보 없음",
        item['menu4'] ?? "메뉴 정보 없음",
        item['menu5'] ?? "메뉴 정보 없음",
      ];

      /*
      final String menu1 = item['menu1'];
      final String menu2 = item['menu2'];
      final String menu3 = item['menu3'];
      final String menu4 = item['menu4'];
      final String menu5 = item['menu5'];
      */

      markers.add(
        Marker(
          markerId: MarkerId(name),
          position: position,
          infoWindow: InfoWindow(title: name),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _colorToHue(crowdColors[crowdLevel] ?? Colors.white),
          ),
          onTap: () {
            _showBottomSheet(
              context,
              name,
              item['restaurant_address'],
              crowdLevel,
              menus, // 안전하게 처리된 메뉴 리스트 전달
              
            );
          },
        ),
      );
    }
  });
}

  LatLng _addressToLatLng(String address) {
    Map<String, LatLng> mockData = {
      "서울특별시 마포구 상수동": LatLng(37.551214, 126.924432),
      "서울특별시 마포구 연남동": LatLng(37.566, 126.923),
      "서울특별시 마포구 와우산로 94": LatLng(37.550100, 126.924432),
      //"서울 마포구 독막로19길 19 1층": LatLng(37.548430, 126.924620),
      "서울 마포구 와우산로 51-6": LatLng(37.54928986921307, 126.92268043756485), // 칸다소바
      "서울 마포구 와우산로 51-9 1층": LatLng(37.5492154404851, 126.92246988415718), // 김덕후의곱창조
      "서울 마포구 와우산로15길 15": LatLng(37.54961841799544, 126.92235186696053), // 윤씨밀방
      "서울 마포구 와우산로15길 30": LatLng(37.54924042728065, 126.92160554230213), // 제순식당
      "서울 마포구 와우산로13길 9 골목집": LatLng(37.54961841799544, 126.92261338233948), // 골목집
      "서울 마포구 와우산로15길 28 1층": LatLng(37.549340906012134, 126.92172557115555), // 후타츠 홍대점
    };
    return mockData[address] ?? const LatLng(37.538214, 126.924432);
  }

  double _colorToHue(Color color) {
    return HSVColor.fromColor(color).hue;
  }

  void _showBottomSheet(BuildContext context, String name, String address, String crowdLevel, List<String> menus) {
    // 메뉴의 초기 수량 상태를 관리하기 위한 Map
    Map<String, int> menuQuantities = {
      for (var menu in menus) menu: 0, // 각 메뉴의 초기 수량을 0으로 설정
    };
    int headcount = 1; // 기본값 1

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 1.0, // 정보창 높이 설정
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // 닫기 버튼
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.grey[200],
                    ),
                    child: const Icon(Icons.close, color: Colors.black),
                  ),
                ],
              ),
              /*const SizedBox(height: 10),
              Text(
                "주소: $address",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),*/
              Row(
                children: [
                  Text(
                    "혼잡도: $crowdLevel",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: crowdColors[crowdLevel] ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const Divider(height: 10),
              const SizedBox(height: 10), // 혼잡도와 메뉴 사이 간격 내가 추가ㅎㅎ
              
              
              // 메뉴 목록 추가
              const Text(
                "메뉴",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),

              /*for (var menu in menus)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(menu, style: const TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (menuQuantities[menu]! > 1) menuQuantities[menu] = menuQuantities[menu]! - 1;
                            });
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        Text('${menuQuantities[menu]}'),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              menuQuantities[menu] = menuQuantities[menu]! + 1;
                            });
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 0), // 각 메뉴 간 간격 설정
                  ],
                ),
                */
                for (var menu in menus)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          menu,
                          style: const TextStyle(fontSize: 20),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (menuQuantities[menu] != null && menuQuantities[menu]! > 0) {
                                  menuQuantities[menu] = menuQuantities[menu]! - 1;
                                }
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                border: Border.all(color: Colors.black, width: 1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  "-",
                                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '${menuQuantities[menu] ?? 0}',
                              style: const TextStyle(fontSize: 20), // 예약 인원과 동일한 스타일 적용
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                // Null 확인 후 값 증가
                                if (menuQuantities[menu] != null) {
                                  menuQuantities[menu] = menuQuantities[menu]! + 1;
                                }
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                border: Border.all(color: Colors.black, width: 1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  "+",
                                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),


              const SizedBox(height: 5), // 메뉴와 예약 인원 사이 간격


              // 예약 인원 추가
              const Text(
                "예약 인원",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 5),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: const Text(
                      "총 인원",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (headcount > 1) {
                              headcount--;
                            }
                          });
                        },
                      borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            border: Border.all(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              "-",
                              style: TextStyle(color: Colors.black, fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('$headcount', style: const TextStyle(fontSize: 20)),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            headcount++;
                          });
                        },
                        borderRadius: BorderRadius.circular(4),
                      /*
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            headcount++;
                          });
                        },
                        */
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            border: Border.all(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              "+",
                              style: TextStyle(color: Colors.black, fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              /*
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (headcount > 1) headcount--;
                      });
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$headcount', style: const TextStyle(fontSize: 18)),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        headcount++;
                      });
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              */
              
              const Spacer(),

              const Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final selectedMenus = menuQuantities.entries
                        .where((entry) => entry.value > 0)
                        .map((entry) => {'menu': entry.key, 'quantity': entry.value})
                        .toList();

                    final orderData = {
                      'user_ID': 'example_user',
                      'restaurant_ID': 'example_restaurant',
                      'menus': selectedMenus,
                      'headcount': headcount,
                    };

                    final response = await http.post(
                      Uri.parse('http://localhost:3000/order'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode(orderData),
                    );

                    if (response.statusCode == 200) {
                      print("Order sent successfully");
                      Navigator.pop(context);
                    } else {
                      print("Failed to send order");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: const Text("주문 전송", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            
              /*
              Padding(
                padding: const EdgeInsets.only(bottom: 10), // 버튼 위로 살짝 이동
                child: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await Future.delayed(const Duration(milliseconds: 200)); // 딜레이
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[300], // 기본 색상
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    child: const Text(
                      "주문 전송",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),*/
            ],
          ),
        );
      },
    );
  }

  void _zoomIn() async {
    final controller = await _controller.future;
    setState(() {
      currentZoomLevel += 1;
      controller.animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
    });
  }

  void _zoomOut() async {
    final controller = await _controller.future;
    setState(() {
      currentZoomLevel -= 1;
      controller.animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 지도
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: initialCameraPosition,
            markers: markers,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            }.toSet(),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false, // Google 로고 제거
          ),
          // 검색창
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, // 매직아일랜드 영역 고려
            left: 16,
            right: 16,
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.text,
              textAlignVertical: TextAlignVertical.center, // 힌트 텍스트 가운데 정렬
              decoration: InputDecoration(
                hintText: "검색",
                hintStyle: const TextStyle(color: Colors.grey), // 연한 글자 색상
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // 새로고침 및 확대/축소 버튼
          Positioned(
            right: 10,
            top: MediaQuery.of(context).padding.top + 80, // 검색창과 겹치지 않도록 아래로 이동
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _fetchData,
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _zoomIn,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "+",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _zoomOut,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "-",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
*/











/*
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();

  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(37.551214, 126.924432), // 홍익대학교 근처
    zoom: 17.0, // 초기 줌 레벨
  );

  double currentZoomLevel = 17.0; // 현재 줌 레벨 상태 관리
  Set<Marker> markers = {}; // 지도에 표시할 마커들
  Map<String, double> crowdHues = {
  "green": 120.0, // 초록색
  "yellow": 60.0, // 밝은 노란색
  "orange": 39.0, // 밝은 주황색 (HSV 기준)
  "red": 0.0,     // 빨간색
  "gray": 0.0,    // 회색은 hue 무시 (혹은 기본값)
  };
  
  Map<String, Color> crowdColors = {
    "green": Colors.green,
    "yellow":const Color.fromARGB(255, 241, 217, 0),
    //"yellow":Colors.yellow,
    //"yellow": const Color.fromARGB(255, 255, 235, 59), // 진한 노란색
    "orange":Colors.orangeAccent,
    //"orange": const Color.fromARGB(255, 237, 154, 0), // 진한 주황색
    "red": Colors.red,
    "gray": Colors.grey,
  };
  

  @override
  void initState() {
    super.initState();
    _fetchData(); // 초기 데이터 요청
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/restaurants'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _addMarkers(data);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }
  /*
  void _addMarkers(List<dynamic> data) {
    setState(() {
      markers.clear();
      for (var item in data) {
        final LatLng position = _addressToLatLng(item['restaurant_address']);
        final String name = item['restaurant_name'];
        final String crowdLevel = item['crowd_level'];

        markers.add(
          Marker(
            markerId: MarkerId(name),
            position: position,
            infoWindow: InfoWindow(title: name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              
            _colorToHue(crowdColors[crowdLevel] ?? Colors.white),
            ),
            onTap: () {
              _showBottomSheet(context, name, item['restaurant_address'], crowdLevel);
            },
          ),
        );
      }
    });
  }
  */

  void _addMarkers(List<dynamic> data) {
  setState(() {
    markers.clear();
    for (var item in data) {
      final LatLng position = _addressToLatLng(item['restaurant_address']);
      final String name = item['restaurant_name'];
      final String crowdLevel = item['crowd_level'];

      // 메뉴 데이터를 안전하게 가져오기
      final List<String> menus = [
        item['menu1'] ?? "메뉴 정보 없음1",
        item['menu2'] ?? "메뉴 정보 없음2",
        item['menu3'] ?? "메뉴 정보 없음",
        item['menu4'] ?? "메뉴 정보 없음",
        item['menu5'] ?? "메뉴 정보 없음",
      ];

      /*
      final String menu1 = item['menu1'];
      final String menu2 = item['menu2'];
      final String menu3 = item['menu3'];
      final String menu4 = item['menu4'];
      final String menu5 = item['menu5'];
      */

      markers.add(
        Marker(
          markerId: MarkerId(name),
          position: position,
          infoWindow: InfoWindow(title: name),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _colorToHue(crowdColors[crowdLevel] ?? Colors.white),
          ),
          onTap: () {
            _showBottomSheet(
              context,
              name,
              item['restaurant_address'],
              crowdLevel,
              menus, // 안전하게 처리된 메뉴 리스트 전달
              
            );
          },
        ),
      );
    }
  });
}

  LatLng _addressToLatLng(String address) {
    Map<String, LatLng> mockData = {
      "서울특별시 마포구 상수동": LatLng(37.551214, 126.924432),
      "서울특별시 마포구 연남동": LatLng(37.566, 126.923),
      "서울특별시 마포구 와우산로 94": LatLng(37.550100, 126.924432),
      //"서울 마포구 독막로19길 19 1층": LatLng(37.548430, 126.924620),
      "서울 마포구 와우산로 51-6": LatLng(37.54928986921307, 126.92268043756485), // 칸다소바
      "서울 마포구 와우산로 51-9 1층": LatLng(37.5492154404851, 126.92246988415718), // 김덕후의곱창조
      "서울 마포구 와우산로15길 15": LatLng(37.54961841799544, 126.92235186696053), // 윤씨밀방
      "서울 마포구 와우산로15길 30": LatLng(37.54924042728065, 126.92160554230213), // 제순식당
      "서울 마포구 와우산로13길 9 골목집": LatLng(37.54961841799544, 126.92261338233948), // 골목집
      "서울 마포구 와우산로15길 28 1층": LatLng(37.549340906012134, 126.92172557115555), // 후타츠 홍대점
    };
    return mockData[address] ?? const LatLng(37.538214, 126.924432);
  }

  double _colorToHue(Color color) {
    return HSVColor.fromColor(color).hue;
  }

  void _showBottomSheet(BuildContext context, String name, String address, String crowdLevel, List<String> menus) {
    // 메뉴의 초기 수량 상태를 관리하기 위한 Map
    Map<String, int> menuQuantities = {
      for (var menu in menus) menu: 1, // 각 메뉴의 초기 수량을 1로 설정
    };
    
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 1.0, // 정보창 높이 설정
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // 닫기 버튼
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.grey[200],
                    ),
                    child: const Icon(Icons.close, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "주소: $address",
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    "혼잡도: $crowdLevel",
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: crowdColors[crowdLevel] ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const Divider(height: 10),
              const SizedBox(height: 10), // 메뉴와 예약 인원 사이 간격 내가 추가ㅎㅎ
              // 메뉴 목록 추가
              const Text(
                "메뉴",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              for (var menu in menus)
                if (menu != null && menu.isNotEmpty)
                  Text("• $menu", style: const TextStyle(fontSize: 20)),

              const SizedBox(height: 10), // 메뉴와 예약 인원 사이 간격
              // 예약 인원 추가
              const Text(
                "예약 인원",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                "예약 인원 정보 없음", // 예약 인원 데이터를 받을 경우 수정
                style: const TextStyle(fontSize: 20),
              ),

              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10), // 버튼 위로 살짝 이동
                child: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await Future.delayed(const Duration(milliseconds: 200)); // 딜레이
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[300], // 기본 색상
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    child: const Text(
                      "주문 전송",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _zoomIn() async {
    final controller = await _controller.future;
    setState(() {
      currentZoomLevel += 1;
      controller.animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
    });
  }

  void _zoomOut() async {
    final controller = await _controller.future;
    setState(() {
      currentZoomLevel -= 1;
      controller.animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 지도
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: initialCameraPosition,
            markers: markers,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            }.toSet(),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false, // Google 로고 제거
          ),
          // 검색창
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, // 매직아일랜드 영역 고려
            left: 16,
            right: 16,
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.text,
              textAlignVertical: TextAlignVertical.center, // 힌트 텍스트 가운데 정렬
              decoration: InputDecoration(
                hintText: "검색",
                hintStyle: const TextStyle(color: Colors.grey), // 연한 글자 색상
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // 새로고침 및 확대/축소 버튼
          Positioned(
            right: 10,
            top: MediaQuery.of(context).padding.top + 80, // 검색창과 겹치지 않도록 아래로 이동
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _fetchData,
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _zoomIn,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "+",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _zoomOut,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "-",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
*/










/*
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();

  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(37.551214, 126.924432), // 홍익대학교 근처
    zoom: 17.0, // 초기 줌 레벨
  );

  double currentZoomLevel = 17.0; // 현재 줌 레벨 상태 관리
  Set<Marker> markers = {}; // 지도에 표시할 마커들
  Map<String, double> crowdHues = {
  "green": 120.0, // 초록색
  "yellow": 60.0, // 밝은 노란색
  "orange": 39.0, // 밝은 주황색 (HSV 기준)
  "red": 0.0,     // 빨간색
  "gray": 0.0,    // 회색은 hue 무시 (혹은 기본값)
  };
  
  Map<String, Color> crowdColors = {
    "green": Colors.green,
    "yellow":const Color.fromARGB(255, 241, 217, 0),
    //"yellow":Colors.yellow,
    //"yellow": const Color.fromARGB(255, 255, 235, 59), // 진한 노란색
    "orange":Colors.orangeAccent,
    //"orange": const Color.fromARGB(255, 237, 154, 0), // 진한 주황색
    "red": Colors.red,
    "gray": Colors.grey,
  };
  

  @override
  void initState() {
    super.initState();
    _fetchData(); // 초기 데이터 요청
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/restaurants'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _addMarkers(data);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }
  /*
  void _addMarkers(List<dynamic> data) {
    setState(() {
      markers.clear();
      for (var item in data) {
        final LatLng position = _addressToLatLng(item['restaurant_address']);
        final String name = item['restaurant_name'];
        final String crowdLevel = item['crowd_level'];

        markers.add(
          Marker(
            markerId: MarkerId(name),
            position: position,
            infoWindow: InfoWindow(title: name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              
            _colorToHue(crowdColors[crowdLevel] ?? Colors.white),
            ),
            onTap: () {
              _showBottomSheet(context, name, item['restaurant_address'], crowdLevel);
            },
          ),
        );
      }
    });
  }
  */

  void _addMarkers(List<dynamic> data) {
  setState(() {
    markers.clear();
    for (var item in data) {
      final LatLng position = _addressToLatLng(item['restaurant_address']);
      final String name = item['restaurant_name'];
      final String crowdLevel = item['crowd_level'];

      // 메뉴 데이터를 안전하게 가져오기
      final List<String> menus = [
        item['menu1'] ?? "메뉴 정보 없음1",
        item['menu2'] ?? "메뉴 정보 없음2",
        item['menu3'] ?? "메뉴 정보 없음",
        item['menu4'] ?? "메뉴 정보 없음",
        item['menu5'] ?? "메뉴 정보 없음",
      ];

      /*
      final String menu1 = item['menu1'];
      final String menu2 = item['menu2'];
      final String menu3 = item['menu3'];
      final String menu4 = item['menu4'];
      final String menu5 = item['menu5'];
      */

      markers.add(
        Marker(
          markerId: MarkerId(name),
          position: position,
          infoWindow: InfoWindow(title: name),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _colorToHue(crowdColors[crowdLevel] ?? Colors.white),
          ),
          onTap: () {
            _showBottomSheet(
              context,
              name,
              item['restaurant_address'],
              crowdLevel,
              menus, // 안전하게 처리된 메뉴 리스트 전달
              
            );
          },
        ),
      );
    }
  });
}

  LatLng _addressToLatLng(String address) {
    Map<String, LatLng> mockData = {
      "서울특별시 마포구 상수동": LatLng(37.551214, 126.924432),
      "서울특별시 마포구 연남동": LatLng(37.566, 126.923),
      "서울특별시 마포구 와우산로 94": LatLng(37.550100, 126.924432),
      //"서울 마포구 독막로19길 19 1층": LatLng(37.548430, 126.924620),
      "서울 마포구 와우산로 51-6": LatLng(37.54928986921307, 126.92268043756485), // 칸다소바
      "서울 마포구 와우산로 51-9 1층": LatLng(37.5492154404851, 126.92246988415718), // 김덕후의곱창조
      "서울 마포구 와우산로15길 15": LatLng(37.54961841799544, 126.92235186696053), // 윤씨밀방
      "서울 마포구 와우산로15길 30": LatLng(37.54924042728065, 126.92160554230213), // 제순식당
      "서울 마포구 와우산로13길 9 골목집": LatLng(37.54961841799544, 126.92261338233948), // 골목집
      "서울 마포구 와우산로15길 28 1층": LatLng(37.549340906012134, 126.92172557115555), // 후타츠 홍대점
    };
    return mockData[address] ?? const LatLng(37.538214, 126.924432);
  }

  double _colorToHue(Color color) {
    return HSVColor.fromColor(color).hue;
  }

  void _showBottomSheet(BuildContext context, String name, String address, String crowdLevel, List<String> menus) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 1.0, // 정보창 높이 설정
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // 닫기 버튼
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.grey[200],
                    ),
                    child: const Icon(Icons.close, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "주소: $address",
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    "혼잡도: $crowdLevel",
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: crowdColors[crowdLevel] ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const Divider(height: 10),
              const SizedBox(height: 10), // 메뉴와 예약 인원 사이 간격 내가 추가ㅎㅎ
              // 메뉴 목록 추가
              const Text(
                "메뉴",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              for (var menu in menus)
                if (menu != null && menu.isNotEmpty)
                  Text("• $menu", style: const TextStyle(fontSize: 20)),

              const SizedBox(height: 10), // 메뉴와 예약 인원 사이 간격
              // 예약 인원 추가
              const Text(
                "예약 인원",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                "예약 인원 정보 없음", // 예약 인원 데이터를 받을 경우 수정
                style: const TextStyle(fontSize: 20),
              ),

              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10), // 버튼 위로 살짝 이동
                child: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await Future.delayed(const Duration(milliseconds: 200)); // 딜레이
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[300], // 기본 색상
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    child: const Text(
                      "주문 전송",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _zoomIn() async {
    final controller = await _controller.future;
    setState(() {
      currentZoomLevel += 1;
      controller.animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
    });
  }

  void _zoomOut() async {
    final controller = await _controller.future;
    setState(() {
      currentZoomLevel -= 1;
      controller.animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 지도
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: initialCameraPosition,
            markers: markers,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            }.toSet(),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false, // Google 로고 제거
          ),
          // 검색창
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, // 매직아일랜드 영역 고려
            left: 16,
            right: 16,
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.text,
              textAlignVertical: TextAlignVertical.center, // 힌트 텍스트 가운데 정렬
              decoration: InputDecoration(
                hintText: "검색",
                hintStyle: const TextStyle(color: Colors.grey), // 연한 글자 색상
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // 새로고침 및 확대/축소 버튼
          Positioned(
            right: 10,
            top: MediaQuery.of(context).padding.top + 80, // 검색창과 겹치지 않도록 아래로 이동
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _fetchData,
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _zoomIn,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "+",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _zoomOut,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "-",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
*/












/*
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();

  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(37.551214, 126.924432), // 홍익대학교 근처
    zoom: 17.0, // 초기 줌 레벨
  );

  double currentZoomLevel = 17.0; // 현재 줌 레벨 상태 관리
  Set<Marker> markers = {}; // 지도에 표시할 마커들
  Map<String, Color> crowdColors = {
    "green": Colors.green,
    "yellow": const Color.fromARGB(255, 255, 235, 59), // 진한 노란색
    "orange": const Color.fromARGB(255, 255, 165, 0), // 진한 주황색
    "red": Colors.red,
    "gray": Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _fetchData(); // 초기 데이터 요청
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/restaurants'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _addMarkers(data);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  void _addMarkers(List<dynamic> data) {
    setState(() {
      markers.clear();
      for (var item in data) {
        final LatLng position = _addressToLatLng(item['restaurant_address']);
        final String name = item['restaurant_name'];
        final String crowdLevel = item['crowd_level'];

        markers.add(
          Marker(
            markerId: MarkerId(name),
            position: position,
            infoWindow: InfoWindow(title: name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _colorToHue(crowdColors[crowdLevel] ?? Colors.grey),
            ),
            onTap: () {
              _showBottomSheet(context, name, item['restaurant_address'], crowdLevel);
            },
          ),
        );
      }
    });
  }

  LatLng _addressToLatLng(String address) {
    Map<String, LatLng> mockData = {
      "서울특별시 마포구 상수동": LatLng(37.551214, 126.924432),
      "서울특별시 마포구 연남동": LatLng(37.566, 126.923),
      "서울특별시 마포구 와우산로 94": LatLng(37.550100, 126.924432),
      "서울 마포구 독막로19길 19 1층": LatLng(37.548430, 126.924620),
      "서울 마포구 와우산로 51-6": LatLng(37.54928986921307, 126.92268043756485), // 칸다소바
      "서울 마포구 와우산로 51-9 1층": LatLng(37.5492154404851, 126.92246988415718), // 김덕후의곱창조
      "서울 마포구 와우산로15길 15": LatLng(37.54961841799544, 126.92235186696053), // 윤씨밀방
      "서울 마포구 와우산로15길 30": LatLng(37.54924042728065, 126.92160554230213), // 제순식당
      "서울 마포구 와우산로13길 9 골목집": LatLng(37.54961841799544, 126.92261338233948), // 골목집
      "서울 마포구 와우산로15길 28 1층": LatLng(37.549340906012134, 126.92172557115555), // 후타츠 홍대점
    };
    return mockData[address] ?? const LatLng(37.538214, 126.924432);
  }

  double _colorToHue(Color color) {
    return HSVColor.fromColor(color).hue;
  }

  void _showBottomSheet(BuildContext context, String name, String address, String crowdLevel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.3, // 정보창 높이 설정
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // 닫기 버튼
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.grey[200],
                    ),
                    child: const Icon(Icons.close, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "주소: $address",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    "혼잡도: $crowdLevel",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: crowdColors[crowdLevel] ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10), // 버튼 위로 살짝 이동
                child: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await Future.delayed(const Duration(milliseconds: 200)); // 딜레이
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[300], // 기본 색상
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    child: const Text(
                      "예약",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _zoomIn() async {
    final controller = await _controller.future;
    setState(() {
      currentZoomLevel += 1;
      controller.animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
    });
  }

  void _zoomOut() async {
    final controller = await _controller.future;
    setState(() {
      currentZoomLevel -= 1;
      controller.animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 지도
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: initialCameraPosition,
            markers: markers,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            }.toSet(),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          // 검색창
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, // 매직아일랜드 영역 고려
            left: 16,
            right: 16,
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: "검색 (음식점 이름 검색 가능)",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // 새로고침 및 확대/축소 버튼
          Positioned(
            right: 10,
            top: MediaQuery.of(context).padding.top + 80, // 검색창과 겹치지 않도록 아래로 이동
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _fetchData,
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _zoomIn,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "+",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _zoomOut,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "-",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
*/








/*
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();

  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(37.551214, 126.924432), // 홍익대학교 근처
    zoom: 17.0, // 초기 줌 레벨
  );

  double currentZoomLevel = 17.0; // 현재 줌 레벨 상태 관리
  Set<Marker> markers = {}; // 지도에 표시할 마커들
  Map<String, Color> crowdColors = {
    "green": Colors.green,
    "yellow": const Color.fromARGB(255, 255, 235, 59), // 진한 노란색
    "orange": const Color.fromARGB(255, 255, 165, 0), // 진한 주황색
    "red": Colors.red,
    "gray": Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _fetchData(); // 초기 데이터 요청
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/restaurants'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _addMarkers(data);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  void _addMarkers(List<dynamic> data) {
    setState(() {
      markers.clear();
      for (var item in data) {
        final LatLng position = _addressToLatLng(item['restaurant_address']);
        final String name = item['restaurant_name'];
        final String crowdLevel = item['crowd_level'];

        markers.add(
          Marker(
            markerId: MarkerId(name),
            position: position,
            infoWindow: InfoWindow(title: name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _colorToHue(crowdColors[crowdLevel] ?? Colors.grey),
            ),
            onTap: () {
              _showBottomSheet(context, name, item['restaurant_address'], crowdLevel);
            },
          ),
        );
      }
    });
  }

  LatLng _addressToLatLng(String address) {
    Map<String, LatLng> mockData = {
      "서울특별시 마포구 상수동": LatLng(37.551214, 126.924432),
      "서울특별시 마포구 연남동": LatLng(37.566, 126.923),
      "서울특별시 마포구 와우산로 94": LatLng(37.550100, 126.924432),
      "서울 마포구 독막로19길 19 1층": LatLng(37.548430, 126.924620),
      "서울 마포구 와우산로 51-6": LatLng(37.54928986921307, 126.92268043756485), // 칸다소바
      "서울 마포구 와우산로 51-9 1층": LatLng(37.5492154404851, 126.92246988415718), // 김덕후의곱창조
      "서울 마포구 와우산로15길 15": LatLng(37.54961841799544, 126.92235186696053), // 윤씨밀방
      "서울 마포구 와우산로15길 30": LatLng(37.54924042728065, 126.92160554230213), // 제순식당
      "서울 마포구 와우산로13길 9 골목집": LatLng(37.54961841799544, 126.92261338233948), // 골목집
      "서울 마포구 와우산로15길 28 1층": LatLng(37.549340906012134, 126.92172557115555), // 후타츠 홍대점
    };
    return mockData[address] ?? const LatLng(37.538214, 126.924432);
  }

  double _colorToHue(Color color) {
    return HSVColor.fromColor(color).hue;
  }

  void _showBottomSheet(BuildContext context, String name, String address, String crowdLevel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.3, // 정보창 높이 설정
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // 닫기 버튼
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.grey[200],
                    ),
                    child: const Icon(Icons.close, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "주소: $address",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    "혼잡도: $crowdLevel",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: crowdColors[crowdLevel] ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10), // 버튼 위로 살짝 이동
                child: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await Future.delayed(const Duration(milliseconds: 200)); // 딜레이
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[300], // 기본 색상
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    child: const Text(
                      "예약",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _zoomIn() async {
    final controller = await _controller.future;
    setState(() {
      currentZoomLevel += 1;
      controller.animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
    });
  }

  void _zoomOut() async {
    final controller = await _controller.future;
    setState(() {
      currentZoomLevel -= 1;
      controller.animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 지도
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: initialCameraPosition,
            markers: markers,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            }.toSet(),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          // 검색창
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, // 매직아일랜드 영역 고려
            left: 16,
            right: 16,
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: "검색 (음식점 이름 검색 가능)",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // 새로고침 및 확대/축소 버튼
          Positioned(
            right: 10,
            top: 110,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _fetchData,
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _zoomIn,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "+",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _zoomOut,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "-",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
*/






