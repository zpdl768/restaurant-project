import 'package:flutter/material.dart';
import 'models.dart';
import 'server_service.dart';

/// 예약 주문 위젯: 오른쪽 하단 "QuickOrder 주문" 영역을 담당
class ReservationWidget extends StatefulWidget {
  final Function(Order) onOrderAccepted; // 수락 시 호출될 콜백 함수

  const ReservationWidget({required this.onOrderAccepted, super.key});

  @override
  _ReservationWidgetState createState() => _ReservationWidgetState();
}

class _ReservationWidgetState extends State<ReservationWidget> {
  final serverService = ServerService();
  Order? currentOrder; // 수신된 주문 데이터

  

  /// 주기적으로 서버에서 주문 데이터를 가져오는 메서드
  void fetchOrderPeriodically() {
    fetchOrderFromServer(); // 초기 호출
    Future.delayed(const Duration(seconds: 20), fetchOrderPeriodically); // 5초마다 반복
  }

  /// 서버로부터 주문 데이터를 가져오는 메서드
  void fetchOrderFromServer() async {
    final order = await serverService.fetchCurrentOrder();
    if (order != null) {
      setState(() {
        currentOrder = order; // 서버에서 받은 주문 데이터를 상태로 저장
      });
    }
  }

  

  
  /// 예약 수락 처리
  void acceptOrder() {
    if (currentOrder != null) {
      serverService.sendReservationResponse(
        currentOrder!.userId,
        currentOrder!.restaurantId,
        'accepted',
      );
      widget.onOrderAccepted(currentOrder!); // 부모 위젯에 전달
      setState(() => currentOrder = null); // 주문 데이터 초기화
    }
  }
  

  /// 예약 거절 처리
  void rejectOrder() {
    if (currentOrder != null) {
      serverService.sendReservationResponse(
        currentOrder!.userId,
        currentOrder!.restaurantId,
        'denied',
      );
      setState(() => currentOrder = null); // 주문 데이터 초기화
    }
  }

  /*
  @override
  void initState() {
    super.initState();
    fetchOrderFromServer(); // 초기화 시 서버에서 주문 데이터를 가져옴
  }
  */
  @override
  void initState() {
    super.initState();
    fetchOrderPeriodically(); // 주기적으로 서버 데이터 가져오기
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // (1) "QuickOrder 주문" 제목 표시
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "QuickOrder 주문",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ),

        // (2) 주문 예약 데이터 표시
        if (currentOrder != null)
          Column(
            children: [
              Text(
                "총 인원: ${currentOrder!.headcount}",
                style: const TextStyle(fontSize: 20),
              ),

              // 수정된 메뉴 표시 로직
              ...currentOrder!.menus.map(
                (menu) => Text(
                  "${menu.name}: ${menu.quantity}개",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              /*
              if (currentOrder!.menu1 != null) Text("menu1: ${currentOrder!.menu1}"),
              if (currentOrder!.menu2 != null) Text("menu2: ${currentOrder!.menu2}"),
              if (currentOrder!.menu3 != null) Text("menu3: ${currentOrder!.menu3}"),
              if (currentOrder!.menu4 != null) Text("menu4: ${currentOrder!.menu4}"),
              if (currentOrder!.menu5 != null) Text("menu5: ${currentOrder!.menu5}"),
              */
              const SizedBox(height: 20),

              // (3) 수락/거절 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: acceptOrder,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 60),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      "수락",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: rejectOrder,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 60),
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      "거절",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        // 데이터가 없는 경우 빈 상태 처리
        if (currentOrder == null)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "예약된 주문이 없습니다.",
              style: TextStyle(fontSize: 18),
            ),
          ),
      ],
    );
  }
}









/*
import 'package:flutter/material.dart';
import 'models.dart';
import 'server_service.dart';

/// 예약 주문 위젯: 오른쪽 하단 "QuickOrder 주문" 영역을 담당
class ReservationWidget extends StatefulWidget {
  final Function(Reservation) onOrderAccepted; // 수락 시 호출될 콜백 함수

  const ReservationWidget({required this.onOrderAccepted, super.key});

  @override
  _ReservationWidgetState createState() => _ReservationWidgetState();
}

class _ReservationWidgetState extends State<ReservationWidget> {
  final serverService = ServerService();
  Reservation? currentOrder; // 수신된 주문 데이터

  /// 서버로부터 예약 데이터를 수신하는 메서드 (시뮬레이션)
  void fetchOrderFromServer() {
    // 서버에서 데이터가 도착했다고 가정
    setState(() {
      currentOrder = Reservation(
        orderId: '123',
        userId: 'user_01',
        restaurantId: '10',
        headcount: 4,
        menu: {'윤씨함박스테이크정식': 2, '머쉬룸투움바파스타': 1},
      );
    });
  }

  /// 예약 수락 처리
  void acceptOrder() {
    if (currentOrder != null) {
      serverService.sendReservationResponse(
        currentOrder!.userId,
        currentOrder!.restaurantId,
        'accepted',
      );
      widget.onOrderAccepted(currentOrder!); // 부모 위젯에 전달
      setState(() => currentOrder = null); // 주문 데이터 초기화
    }
  }

  /// 예약 거절 처리
  void rejectOrder() {
    if (currentOrder != null) {
      serverService.sendReservationResponse(
        currentOrder!.userId,
        currentOrder!.restaurantId,
        'denied',
      );
      setState(() => currentOrder = null); // 주문 데이터 초기화
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // (1) "QuickOrder 주문" 제목 표시
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "QuickOrder 주문",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ),

        // (2) 주문 예약 데이터 표시
        if (currentOrder != null)
          Column(
            children: [
              Text(
                "총 인원: ${currentOrder!.headcount}",
                style: const TextStyle(fontSize: 20),
              ),
              ...currentOrder!.menu.entries.map(
                (entry) => Text(
                  "${entry.key}: ${entry.value}개",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),

              // (3), (4) 수락/거절 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: acceptOrder,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 60),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      "수락",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: rejectOrder,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 60),
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      "거절",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        // 데이터가 없는 경우 빈 상태 처리
        if (currentOrder == null)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "예약된 주문이 없습니다.",
              style: TextStyle(fontSize: 18),
            ),
          ),
      ],
    );
  }
}
*/









/*
import 'package:flutter/material.dart';
import 'models.dart'; // Reservation 모델 클래스 (예약 데이터를 위한 모델 파일)
import 'server_service.dart'; // 서버 통신 서비스 클래스

/// 예약 주문을 표시하고 수락/거절할 수 있는 위젯입니다.
/// 수락 시 특정 콜백 함수 `onOrderAccepted`를 실행합니다.
class ReservationWidget extends StatefulWidget {
  final Function(Reservation) onOrderAccepted; // 주문 수락 시 실행할 콜백 함수

  // 생성자: 부모 위젯에서 콜백 함수 `onOrderAccepted`를 필수로 전달받습니다.
  const ReservationWidget({required this.onOrderAccepted, super.key});

  @override
  _ReservationWidgetState createState() => _ReservationWidgetState(); // State 생성
}

/// 예약 주문 위젯의 상태 클래스
class _ReservationWidgetState extends State<ReservationWidget> {
  Reservation? currentOrder; // 현재 표시되는 예약 주문 (없으면 null)
  final serverService = ServerService(); // 서버 통신을 위한 서비스 객체

  /// 서버에서 예약 데이터를 수신하는 메서드 (예제용 하드코딩 데이터)
  void fetchOrderFromServer() {
    // UI 업데이트를 위해 setState 사용
    setState(() {
      currentOrder = Reservation(
        orderId: '123', // 주문 ID
        userId: 'user1', // 사용자 ID
        restaurantId: '10', // 레스토랑 ID
        headcount: 4, // 총 인원 수
        menu: {'윤씨함박스테이크정식': 2, '명란크림우동과 계란볶음밥': 1}, // 메뉴 및 수량
      );
    });
  }

  /// 예약을 **수락**했을 때 실행되는 메서드
  void acceptOrder() {
    if (currentOrder != null) {
      // 부모 위젯에 수락된 주문 정보를 전달
      widget.onOrderAccepted(currentOrder!); 

      // 서버에 예약 수락 응답을 보냄
      serverService.sendReservationResponse(
        currentOrder!.userId,       // 사용자 ID
        currentOrder!.restaurantId, // 레스토랑 ID
        'accepted',                 // 응답 상태: 수락
      );

      // 현재 예약 내역을 초기화하여 화면에서 제거
      setState(() {
        currentOrder = null;
      });
    }
  }

  /// 예약을 **거절**했을 때 실행되는 메서드
  void rejectOrder() {
    if (currentOrder != null) {
      // 서버에 예약 거절 응답을 보냄
      serverService.sendReservationResponse(
        currentOrder!.userId,       // 사용자 ID
        currentOrder!.restaurantId, // 레스토랑 ID
        'denied',                   // 응답 상태: 거절
      );

      // 현재 예약 내역을 초기화하여 화면에서 제거
      setState(() {
        currentOrder = null;
      });
    }
  }

  /// 화면 UI를 빌드하는 메서드
  @override
  Widget build(BuildContext context) {
    return Column( // 화면을 세로 방향(Column)으로 구성
      crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
      children: [
        // 제목 표시 부분
        const Padding(
          padding: EdgeInsets.all(8.0), // 전체 패딩 추가
          child: Text(
            "QuickOrder 주문", // 제목 텍스트
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // 스타일
          ),
        ),
        // 현재 예약 주문이 있는 경우에만 표시
        if (currentOrder != null)
          Expanded(
            child: Column( // 수락/거절 버튼 및 주문 정보 표시
              mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
              children: [
                // 총 인원 표시
                Text("총 인원: ${currentOrder!.headcount}"),
                
                // 메뉴 항목과 개수를 나열 (Map의 각 항목을 Text 위젯으로 변환)
                ...currentOrder!.menu.entries.map(
                  (entry) => Text("${entry.key}: ${entry.value}개"),
                ),

                // 수락/거절 버튼을 포함하는 Row 위젯
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // 버튼을 중앙에 배치
                  children: [
                    // 수락 버튼
                    ElevatedButton(
                      onPressed: acceptOrder, // 수락 버튼 클릭 시 실행
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 50), // 버튼 크기 지정
                      ),
                      child: const Text("수락"), // 버튼 텍스트
                    ),
                    const SizedBox(width: 16), // 버튼 간 간격

                    // 거절 버튼
                    ElevatedButton(
                      onPressed: rejectOrder, // 거절 버튼 클릭 시 실행
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 50), // 버튼 크기 지정
                      ),
                      child: const Text("거절"), // 버튼 텍스트
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
*/












/*
import 'package:flutter/material.dart';
import 'models.dart'; // Reservation 모델 클래스
import 'server_service.dart'; // 서버 통신 서비스

class ReservationWidget extends StatefulWidget {
  final Function(Reservation) onOrderAccepted; // 수락 시 호출되는 콜백 함수
  const ReservationWidget({required this.onOrderAccepted, super.key});

  @override
  _ReservationWidgetState createState() => _ReservationWidgetState();
}

class _ReservationWidgetState extends State<ReservationWidget> {
  Reservation? currentOrder; // 현재 표시되는 예약 주문
  final serverService = ServerService(); // 서버 통신 서비스

  /// 서버에서 예약 데이터를 수신하는 메서드 (예시용)
  void fetchOrderFromServer() {
    setState(() {
      currentOrder = Reservation(
        orderId: '123',
        userId: 'user1',
        restaurantId: '10',
        headcount: 4,
        menu: {'윤씨함박스테이크정식': 2, '명란크림우동과 계란볶음밥': 1},
      );
    });
  }

  /// 수락 버튼을 눌렀을 때 실행되는 메서드
  void acceptOrder() {
    if (currentOrder != null) {
      widget.onOrderAccepted(currentOrder!); // PendingWidget으로 주문 전달
      serverService.sendReservationResponse(
        currentOrder!.userId,
        currentOrder!.restaurantId,
        'accepted',
      );
      setState(() {
        currentOrder = null; // 현재 예약 내역 초기화
      });
    }
  }

  /// 거절 버튼을 눌렀을 때 실행되는 메서드
  void rejectOrder() {
    if (currentOrder != null) {
      serverService.sendReservationResponse(
        currentOrder!.userId,
        currentOrder!.restaurantId,
        'denied',
      );
      setState(() {
        currentOrder = null; // 현재 예약 내역 초기화
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "QuickOrder 주문",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        if (currentOrder != null)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("총 인원: ${currentOrder!.headcount}"),
                ...currentOrder!.menu.entries.map(
                  (entry) => Text("${entry.key}: ${entry.value}개"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: acceptOrder,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 50)), // 버튼 크기 조정
                      child: const Text("수락"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: rejectOrder,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 50)), // 버튼 크기 조정
                      child: const Text("거절"),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
*/












/*import 'package:flutter/material.dart'; // Flutter UI를 구성하는 기본 패키지
import 'models.dart'; // 예약 모델을 사용하기 위해 가져옴
import 'server_service.dart'; // 서버 통신 기능을 가져옴

/// 주문 예약 정보를 표시하고 관리하는 UI 위젯
class ReservationWidget extends StatelessWidget {
  final Reservation reservation; // 예약 정보를 저장하는 변수
  final VoidCallback onAccepted; // 예약을 수락했을 때 실행되는 콜백 함수
  final VoidCallback onRejected; // 예약을 거절했을 때 실행되는 콜백 함수

  /// 생성자: 예약 정보와 수락/거절 콜백 함수를 받습니다.
  const ReservationWidget({
    required this.reservation,
    required this.onAccepted,
    required this.onRejected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4, // 카드에 그림자를 추가해 입체감 부여
      margin: const EdgeInsets.all(8.0), // 카드의 외부 여백 설정
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // 카드의 모서리를 둥글게 설정
        side: const BorderSide(color: Colors.black, width: 1.0), // 카드 테두리 설정
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // 카드 내부 여백 설정
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 좌측 정렬
          children: [
            /// 주문 예약의 헤더 부분 (총 인원 수 표시)
            Text(
              "총 인원: ${reservation.headcount}명", // headcount 변수로 인원 수 표시
              style: const TextStyle(
                fontSize: 18, // 글씨 크기
                fontWeight: FontWeight.bold, // 글씨 굵기
                color: Colors.black, // 글씨 색상
              ),
            ),
            const SizedBox(height: 8), // 헤더와 메뉴 목록 사이 간격 추가

            /// 주문 예약의 메뉴 목록을 표시하는 부분
            ...reservation.menu.entries.map((menuItem) {
              // menu 맵에서 키(메뉴 이름)와 값(수량)을 가져와 표시
              return Text(
                "${menuItem.key} x ${menuItem.value}", // 메뉴 이름과 수량 표시
                style: const TextStyle(
                  fontSize: 16, // 글씨 크기
                  color: Colors.black, // 글씨 색상
                ),
              );
            }).toList(), // map을 리스트로 변환

            const SizedBox(height: 12), // 메뉴 목록과 버튼 사이 간격 추가

            /// 수락 및 거절 버튼 영역
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // 두 버튼을 양 끝으로 정렬
              children: [
                /// 수락 버튼
                ElevatedButton(
                  onPressed: () {
                    // 서버에 예약 수락 상태를 전송
                    ServerService().sendReservationResponse(
                      reservation.userId, "restaurant_ID", "accepted",
                    );
                    onAccepted(); // 수락 콜백 함수 실행
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // 버튼 배경색
                  ),
                  child: const Text(
                    "주문 수락", // 버튼 텍스트
                    style: TextStyle(color: Colors.white), // 텍스트 색상
                  ),
                ),

                /// 거절 버튼
                ElevatedButton(
                  onPressed: () {
                    // 서버에 예약 거절 상태를 전송
                    ServerService().sendReservationResponse(
                      reservation.userId, "restaurant_ID", "rejected",
                    );
                    onRejected(); // 거절 콜백 함수 실행
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // 버튼 배경색
                  ),
                  child: const Text(
                    "주문 거절", // 버튼 텍스트
                    style: TextStyle(color: Colors.white), // 텍스트 색상
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
*/