
import 'dart:convert'; // JSON 데이터 변환을 위해 사용
import 'package:http/http.dart' as http; // HTTP 요청 라이브러리
import 'models.dart';

/// 서버와 통신하는 기능을 제공하는 클래스
class ServerService {
  final String baseUrl = "http://localhost:3000"; // 서버의 기본 주소

  /// 서버에 좌석 점유율 데이터를 전송하는 메서드
  Future<void> sendCrowdLevel(int restaurantId, int occupiedSeats, int totalSeats) async {
    // POST 요청을 통해 서버로 데이터를 전송
    final response = await http.post(
      Uri.parse('$baseUrl/crowd_level'), // 요청을 보낼 엔드포인트 URL
      headers: {'Content-Type': 'application/json'}, // 요청의 데이터 타입을 JSON으로 설정
      body: jsonEncode({
        'restaurant_ID': restaurantId,   // 레스토랑 ID
        'occupied_seats': occupiedSeats, // 현재 점유된 좌석 수
        'total_seats': totalSeats,       // 전체 좌석 수
      }),
    );

    // 서버 응답 확인
    if (response.statusCode != 200) {
      // 오류 발생 시 예외를 던짐
      throw Exception("Failed to send crowd level.");
    }
  }


/// 서버에서 현재 주문 데이터를 가져오는 메서드
Future<Order?> fetchCurrentOrder() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/current_order'));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      print("Fetched order: $jsonData"); // 디버그 로그 추가
      return Order.fromJson(jsonData); // JSON 데이터를 Order 객체로 변환
    } else {
      print("No current order: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    print("Error fetching current order: $e");
    return null;
  }
}





/*
  /// 서버에서 주문 데이터를 가져오는 메서드
  Future<Order?> fetchOrder() async {
    try {
      //final response = await http.get(Uri.parse('$baseUrl/reservation'));
      final response = await http.get(Uri.parse('reservation'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return Order.fromJson(jsonData); // JSON 데이터를 Order 객체로 변환
      } else {
        throw Exception("Failed to fetch order data.");
      }
    } catch (e) {
      print("Error fetching order: $e");
      return null;
    }
  }
*/





  /*
  /// 서버에서 주문 데이터를 가져오는 메서드
  Future<Order?> fetchOrder() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/order'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return Order.fromJson(jsonData); // JSON 데이터를 Order 객체로 변환
      } else {
        throw Exception("Failed to fetch order data.");
      }
    } catch (e) {
      print("Error fetching order: $e");
      return null;
    }
  }
  */



  /// 예약 수락 또는 거절 상태를 서버에 전송하는 메서드
  Future<void> sendReservationResponse(String userId, String restaurantId, String status) async {
    // 상태에 따라 엔드포인트를 결정 (수락 또는 거절)
    final endpoint = status == 'accepted' ? '/reservation_accepted' : '/reservation_denied';

    // POST 요청을 통해 서버로 데이터를 전송
    await http.post(
      Uri.parse('$baseUrl$endpoint'), // 요청을 보낼 엔드포인트 URL
      headers: {'Content-Type': 'application/json'}, // 요청의 데이터 타입을 JSON으로 설정
      body: jsonEncode({
        'restaurant_ID': restaurantId, // 레스토랑 ID
        'user_ID': userId,             // 사용자 ID
        'status': status,              // 상태: 수락 또는 거절
      }),
    );
  }

  /// 서버에 주문 완료 상태를 전송하는 메서드
  Future<void> sendOrderComplete(String userId, String restaurantId) async {
    // POST 요청을 통해 서버로 데이터를 전송
    await http.post(
      Uri.parse('$baseUrl/reservation_complete'), // 엔드포인트 URL
      headers: {'Content-Type': 'application/json'}, // 요청의 데이터 타입을 JSON으로 설정
      body: jsonEncode({
        'restaurant_ID': restaurantId, // 레스토랑 ID
        'user_ID': userId,             // 사용자 ID
      }),
    );
  }
}