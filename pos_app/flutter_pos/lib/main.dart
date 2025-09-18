import 'package:flutter/material.dart';
import 'models.dart';
import 'table_widget.dart';
import 'order_widget.dart';
import 'reservation_widget.dart';
import 'server_service.dart';

void main() {
  runApp(const POSApp());
}

class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const POSHomePage(),
    );
  }
}

class POSHomePage extends StatefulWidget {
  const POSHomePage({super.key});

  @override
  _POSHomePageState createState() => _POSHomePageState();
}

class _POSHomePageState extends State<POSHomePage> {
  final ServerService serverService = ServerService(); // ServerService 초기화
  // 20개의 테이블 데이터 생성
  final List<TableModel> tables = List.generate(
    20,
    (index) => TableModel(
      tableNumber: index + 1,
      seats: 2, // 각 테이블은 2인용
      hasOrders: false,
    ),
  );

  TableModel? selectedTable; // 선택된 테이블

  /// 테이블 선택 시 호출되는 함수
  void selectTable(TableModel table) {
    setState(() {
      selectedTable = table;
    });
  }

  /// 주문 초기화 함수 (결제)
  void clearOrders() {
    setState(() {
      selectedTable?.clearOrders(); // 테이블의 주문 내역 초기화
    });
    updateServerWithCrowdLevel(); // 서버로 좌석 상태 업데이트
  }

  /// 테이블 박스에 주문 내역을 추가하는 함수
  void placeOrder(String orderDetails) {
    setState(() {
      if (selectedTable != null) {
        selectedTable!.orderDetails = orderDetails; // 주문 내역 추가
        selectedTable!.hasOrders = true; // 테이블에 주문 존재 여부 업데이트
      }
    });
    updateServerWithCrowdLevel(); // 서버로 좌석 상태 업데이트
  }

  /// 주문 상태 변경 시 서버로 업데이트를 수행하는 함수
  void onOrderChanged() {
    updateServerWithCrowdLevel(); // 주문 상태가 변경될 때마다 서버 업데이트
  }

  /// 서버로 혼잡도 정보를 업데이트하는 함수
  void updateServerWithCrowdLevel() {
    final occupiedSeats = getOccupiedSeats();
    final totalSeats = getTotalSeats();
    const restaurantId = 10;

    serverService.sendCrowdLevel(restaurantId, occupiedSeats, totalSeats).catchError((error) {
      print("서버 업데이트 실패: $error");
    });
  }

  /// 주문 내역이 있는 테이블의 좌석 수 합산
  int getOccupiedSeats() {
    return tables
        .where((table) => table.hasOrders) // 주문 내역이 있는 테이블만 필터링
        .fold(0, (sum, table) => sum + table.seats); // 좌석 수 합산
  }

  /// 전체 테이블의 좌석 수 합산
  int getTotalSeats() {
    return tables.fold(0, (sum, table) => sum + table.seats); // 좌석 수 합산
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 왼쪽 영역: 테이블 목록
          Expanded(
            flex: 3,
            child: TableWidget(
              tables: tables, // 테이블 목록 데이터 전달
              onTableSelected: selectTable, // 테이블 선택 콜백 함수
            ),
          ),

          // 오른쪽 영역: 선택된 테이블의 주문 UI 및 예약 UI
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // 선택된 테이블의 주문 UI
                if (selectedTable != null)
                  Expanded(
                    flex: 2, // OrderWidget 비율을 더 크게 설정
                    child: OrderWidget(
                      table: selectedTable!, // 선택된 테이블 정보 전달
                      onClearOrders: () {
                        clearOrders(); // 결제(주문 초기화) 함수
                        updateServerWithCrowdLevel(); // 좌석 정보를 서버로 동기화
                      },
                      onOrderPlaced: (orderDetails) {
                        placeOrder(orderDetails); // 주문 내역 추가 함수 호출
                        updateServerWithCrowdLevel(); // 좌석 정보를 서버로 동기화
                      },
                      onOrderChanged: updateServerWithCrowdLevel,
                    ),
                  ),

                const SizedBox(height: 15), // 여백 추가
                
                // 검은색 경계선 추가
                Container(
                  height: 2, // 경계선 두께
                  color: Colors.black, // 경계선 색상
                ),

                const SizedBox(height: 15), // 여백 추가

                // 오른쪽 하단 영역: ReservationWidget
                Expanded(
                  flex: 1, // ReservationWidget의 높이 비율을 조정
                  child: ReservationWidget(
                    onOrderAccepted: (reservation) {
                      // 수정된 구조 반영
                      print("주문 수락됨:");
                      for (var menu in reservation.menus) {
                        print("${menu.name}: ${menu.quantity}개");
                      }
                      // 예약 수락 시 추가적으로 처리할 작업
                    },
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
import 'package:flutter/material.dart';
import 'models.dart';
import 'table_widget.dart';
import 'order_widget.dart';
import 'pending_widget.dart';
import 'reservation_widget.dart';
import 'server_service.dart';

void main() {
  runApp(const POSApp());
}

class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const POSHomePage(),
    );
  }
}

class POSHomePage extends StatefulWidget {
  const POSHomePage({super.key});

  @override
  _POSHomePageState createState() => _POSHomePageState();
}

class _POSHomePageState extends State<POSHomePage> {
  final ServerService serverService = ServerService(); // ServerService 초기화
  // 20개의 테이블 데이터 생성
  final List<TableModel> tables = List.generate(
    20,
    (index) => TableModel(
      tableNumber: index + 1,
      seats: 2, // 각 테이블은 2인용
      hasOrders: false,
    ),
  );

  
  TableModel? selectedTable; // 선택된 테이블

  /// 테이블 선택 시 호출되는 함수
  void selectTable(TableModel table) {
    setState(() {
      selectedTable = table;
    });
  }

  /// 주문 초기화 함수 (결제)
  void clearOrders() {
    setState(() {
      selectedTable?.clearOrders(); // 테이블의 주문 내역 초기화
    });
    updateServerWithCrowdLevel(); // 서버로 좌석 상태 업데이트
  }

  /// 테이블 박스에 주문 내역을 추가하는 함수
  void placeOrder(String orderDetails) {
    setState(() {
      if (selectedTable != null) {
        selectedTable!.orderDetails = orderDetails; // 주문 내역 추가
        selectedTable!.hasOrders = true; // 테이블에 주문 존재 여부 업데이트
      }
    });
    updateServerWithCrowdLevel(); // 서버로 좌석 상태 업데이트
  }

  /// 주문 상태 변경 시 서버로 업데이트를 수행하는 함수
  void onOrderChanged() {
    updateServerWithCrowdLevel(); // 주문 상태가 변경될 때마다 서버 업데이트
  }

  void updateServerWithCrowdLevel() {
    final occupiedSeats = getOccupiedSeats();
    final totalSeats = getTotalSeats();
    const restaurantId = 10;

    serverService.sendCrowdLevel(restaurantId, occupiedSeats, totalSeats).catchError((error) {
      print("서버 업데이트 실패: $error");
    });
  }

  /// 주문 내역이 있는 테이블의 좌석 수 합산
  int getOccupiedSeats() {
    return tables
        .where((table) => table.hasOrders) // 주문 내역이 있는 테이블만 필터링
        .fold(0, (sum, table) => sum + table.seats); // 좌석 수 합산
  }

  /// 전체 테이블의 좌석 수 합산
  int getTotalSeats() {
    return tables.fold(0, (sum, table) => sum + table.seats); // 좌석 수 합산
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 왼쪽 영역: 테이블 목록
          Expanded(
            flex: 3,
            child: TableWidget(
              tables: tables, // 테이블 목록 데이터 전달
              onTableSelected: selectTable, // 테이블 선택 콜백 함수
            ),
          ),

          // 오른쪽 영역: 선택된 테이블의 주문 UI
          Expanded(
            flex: 2,
            child: selectedTable != null
                ? OrderWidget(
                    table: selectedTable!, // 선택된 테이블 정보 전달
                    onClearOrders: () {
                      clearOrders(); // 결제(주문 초기화) 함수
                      updateServerWithCrowdLevel(); // 좌석 정보를 서버로 동기화
                    },
                    onOrderPlaced: (orderDetails) {
                      placeOrder(orderDetails); // 주문 내역 추가 함수 호출
                      updateServerWithCrowdLevel(); // 좌석 정보를 서버로 동기화
                    },
                    onOrderChanged: updateServerWithCrowdLevel,
                  )
                : const Center(
                    child: Text(
                      "테이블을 선택해주세요.",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
*/









/*
import 'package:flutter/material.dart';
import 'models.dart';
import 'table_widget.dart';
import 'order_widget.dart';
import 'pending_widget.dart';
import 'reservation_widget.dart';
import 'server_service.dart';

void main() {
  runApp(const POSApp());
}

class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const POSHomePage(),
    );
  }
}

class POSHomePage extends StatefulWidget {
  const POSHomePage({super.key});

  @override
  _POSHomePageState createState() => _POSHomePageState();
}

class _POSHomePageState extends State<POSHomePage> {
  final ServerService serverService = ServerService(); // ServerService 초기화
  // 20개의 테이블 데이터 생성
  final List<TableModel> tables = List.generate(
    20,
    (index) => TableModel(
      tableNumber: index + 1,
      seats: 2, // 각 테이블은 2인용
      hasOrders: false,
    ),
  );

  
  TableModel? selectedTable; // 선택된 테이블

  /// 테이블 선택 시 호출되는 함수
  void selectTable(TableModel table) {
    setState(() {
      selectedTable = table;
    });
  }

  /// 주문 초기화 함수 (결제)
  void clearOrders() {
    setState(() {
      selectedTable?.clearOrders(); // 테이블의 주문 내역 초기화
    });
    updateServerWithCrowdLevel(); // 서버로 좌석 상태 업데이트
  }

  /// 테이블 박스에 주문 내역을 추가하는 함수
  void placeOrder(String orderDetails) {
    setState(() {
      if (selectedTable != null) {
        selectedTable!.orderDetails = orderDetails; // 주문 내역 추가
        selectedTable!.hasOrders = true; // 테이블에 주문 존재 여부 업데이트
      }
    });
    updateServerWithCrowdLevel(); // 서버로 좌석 상태 업데이트
  }

  /// 주문 상태 변경 시 서버로 업데이트를 수행하는 함수
  void onOrderChanged() {
    updateServerWithCrowdLevel(); // 주문 상태가 변경될 때마다 서버 업데이트
  }

  void updateServerWithCrowdLevel() {
    final occupiedSeats = getOccupiedSeats();
    final totalSeats = getTotalSeats();
    const restaurantId = 1;

    serverService.sendCrowdLevel(restaurantId, occupiedSeats, totalSeats).catchError((error) {
      print("서버 업데이트 실패: $error");
    });
  }

  /// 주문 내역이 있는 테이블의 좌석 수 합산
  int getOccupiedSeats() {
    return tables
        .where((table) => table.hasOrders) // 주문 내역이 있는 테이블만 필터링
        .fold(0, (sum, table) => sum + table.seats); // 좌석 수 합산
  }

  /// 전체 테이블의 좌석 수 합산
  int getTotalSeats() {
    return tables.fold(0, (sum, table) => sum + table.seats); // 좌석 수 합산
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 왼쪽 영역: 테이블 목록
          Expanded(
            flex: 3,
            child: TableWidget(
              tables: tables, // 테이블 목록 데이터 전달
              onTableSelected: selectTable, // 테이블 선택 콜백 함수
            ),
          ),

          // 오른쪽 영역: 선택된 테이블의 주문 UI
          Expanded(
            flex: 2,
            child: selectedTable != null
                ? OrderWidget(
                    table: selectedTable!, // 선택된 테이블 정보 전달
                    onClearOrders: () {
                      clearOrders(); // 결제(주문 초기화) 함수
                      final occupiedSeats = getOccupiedSeats();
                      final totalSeats = getTotalSeats();
                      print("occupied_seats: $occupiedSeats, total_seats: $totalSeats");
                    },
                    onOrderPlaced: placeOrder, // 주문 내역 추가 함수 전달
                  )
                : const Center(
                    child: Text(
                      "테이블을 선택해주세요.",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
*/







/*
import 'package:flutter/material.dart';
import 'models.dart';
import 'table_widget.dart';
import 'order_widget.dart';
import 'pending_widget.dart';
import 'reservation_widget.dart';

void main() {
  runApp(const POSApp());
}

class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const POSHomePage(),
    );
  }
}

class POSHomePage extends StatefulWidget {
  const POSHomePage({super.key});

  @override
  _POSHomePageState createState() => _POSHomePageState();
}

class _POSHomePageState extends State<POSHomePage> {
  // 20개의 테이블 데이터 생성
  final List<TableModel> tables = List.generate(
    20,
    (index) => TableModel(
      tableNumber: index + 1,
      seats: 2, // 각 테이블은 2인용
      hasOrders: false,
    ),
  );

  TableModel? selectedTable; // 선택된 테이블

  /// 테이블 선택 시 호출되는 함수
  void selectTable(TableModel table) {
    setState(() {
      selectedTable = table;
    });
  }

  /// 주문 초기화 함수 (결제)
  void clearOrders() {
    setState(() {
      selectedTable?.clearOrders(); // 테이블의 주문 내역 초기화
    });
  }

  /// 테이블 박스에 주문 내역을 추가하는 함수
  void placeOrder(String orderDetails) {
    setState(() {
      if (selectedTable != null) {
        selectedTable!.orderDetails = orderDetails; // 주문 내역 추가
        selectedTable!.hasOrders = true; // 테이블에 주문 존재 여부 업데이트
      }
    });
  }

  /// 주문 내역이 있는 테이블의 좌석 수 합산
  int getOccupiedSeats() {
    return tables
        .where((table) => table.hasOrders) // 주문 내역이 있는 테이블만 필터링
        .fold(0, (sum, table) => sum + table.seats); // 좌석 수 합산
  }

  /// 전체 테이블의 좌석 수 합산
  int getTotalSeats() {
    return tables.fold(0, (sum, table) => sum + table.seats); // 좌석 수 합산
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 왼쪽 영역: 테이블 목록
          Expanded(
            flex: 3,
            child: TableWidget(
              tables: tables, // 테이블 목록 데이터 전달
              onTableSelected: selectTable, // 테이블 선택 콜백 함수
            ),
          ),

          // 오른쪽 영역: 선택된 테이블의 주문 UI
          Expanded(
            flex: 2,
            child: selectedTable != null
                ? OrderWidget(
                    table: selectedTable!, // 선택된 테이블 정보 전달
                    onClearOrders: () {
                      clearOrders(); // 결제(주문 초기화) 함수
                      final occupiedSeats = getOccupiedSeats();
                      final totalSeats = getTotalSeats();
                      print("occupied_seats: $occupiedSeats, total_seats: $totalSeats");
                    },
                    onOrderPlaced: placeOrder, // 주문 내역 추가 함수 전달
                  )
                : const Center(
                    child: Text(
                      "테이블을 선택해주세요.",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
*/










/*
import 'package:flutter/material.dart';
import 'models.dart';
import 'table_widget.dart';
import 'order_widget.dart';
import 'pending_widget.dart';
import 'reservation_widget.dart';

void main() {
  runApp(const POSApp());
}

class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const POSHomePage(),
    );
  }
}

class POSHomePage extends StatefulWidget {
  const POSHomePage({super.key});

  @override
  _POSHomePageState createState() => _POSHomePageState();
}

class _POSHomePageState extends State<POSHomePage> {
  // 20개의 테이블 데이터 생성
  final List<TableModel> tables = List.generate(
    20,
    (index) => TableModel(
      tableNumber: index + 1,
      seats: 2, // 각 테이블은 2인용
      hasOrders: false,
    ),
  );

  TableModel? selectedTable; // 선택된 테이블

  /// 테이블 선택 시 호출되는 함수
  void selectTable(TableModel table) {
    setState(() {
      selectedTable = table;
    });
  }

  /// 주문 초기화 함수 (결제)
  void clearOrders() {
    setState(() {
      selectedTable?.clearOrders(); // 테이블의 주문 내역 초기화
    });
  }

  /// 테이블 박스에 주문 내역을 추가하는 함수
  void placeOrder(String orderDetails) {
    setState(() {
      if (selectedTable != null) {
        selectedTable!.orderDetails = orderDetails; // 주문 내역 추가
        selectedTable!.hasOrders = true; // 테이블에 주문 존재 여부 업데이트
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 왼쪽 영역: 테이블 목록
          Expanded(
            flex: 3,
            child: TableWidget(
              tables: tables, // 테이블 목록 데이터 전달
              onTableSelected: selectTable, // 테이블 선택 콜백 함수
            ),
          ),

          // 오른쪽 영역: 선택된 테이블의 주문 UI
          Expanded(
            flex: 2,
            child: selectedTable != null
                ? OrderWidget(
                    table: selectedTable!, // 선택된 테이블 정보 전달
                    onClearOrders: clearOrders, // 결제(주문 초기화) 함수 전달
                    onOrderPlaced: placeOrder, // 주문 내역 추가 함수 전달
                  )
                : const Center(
                    child: Text(
                      "테이블을 선택해주세요.",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
*/







/*
import 'package:flutter/material.dart';
import 'models.dart';
import 'table_widget.dart';
import 'order_widget.dart';
import 'pending_widget.dart';
import 'reservation_widget.dart';

void main() {
  runApp(const POSApp());
}

class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const POSHomePage(),
    );
  }
}

class POSHomePage extends StatefulWidget {
  const POSHomePage({super.key});

  @override
  _POSHomePageState createState() => _POSHomePageState();
}

class _POSHomePageState extends State<POSHomePage> {
  // 20개의 테이블 데이터 생성
  final List<TableModel> tables = List.generate(
    20,
    (index) => TableModel(
      tableNumber: index + 1,
      seats: 2, // 각 테이블은 2인용
      hasOrders: false,
    ),
  );

  TableModel? selectedTable; // 선택된 테이블

  /// 테이블 선택 시 호출되는 함수
  void selectTable(TableModel table) {
    setState(() {
      selectedTable = table;
    });
  }

  /// 주문 초기화 함수
  void clearOrders() {
    setState(() {
      selectedTable?.clearOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 왼쪽 영역: 테이블 목록
          Expanded(
            flex: 2,
            child: TableWidget(
              tables: tables, // 필수 파라미터 전달
              onTableSelected: selectTable, // 선택된 테이블 업데이트
            ),
          ),
          // 오른쪽 영역: 주문 화면
          Expanded(
            flex: 2,
            child: selectedTable != null
                ? OrderWidget(
                    table: selectedTable!, // 필수 파라미터 전달
                    onClearOrders: clearOrders, // 주문 초기화 함수
                  )
                : const Center(
                    child: Text(
                      "테이블을 선택해주세요.",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ),
        ],
      ),
      /*bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () {
            // 테이블 정보 수정 화면으로 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const Placeholder()), // 임시 화면 (Placeholder)
            );
          },
          child: const Text("테이블 정보 수정"),
        ),
      ), */
    );
  }
}
*/









/*
import 'package:flutter/material.dart';
import 'table_widget.dart';
import 'order_widget.dart';
import 'pending_widget.dart';
import 'reservation_widget.dart';
import 'models.dart';

void main() {
  runApp(const POSApp());
}

class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: POSHomePage(),
    );
  }
}

class POSHomePage extends StatelessWidget {
  const POSHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 3)), // 외곽선
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(child: TableWidget()), // 왼쪽 상단
                  Expanded(child: PendingWidget()), // 왼쪽 하단
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(child: OrderWidget()), // 오른쪽 상단
                  Expanded(child: ReservationWidget()), // 오른쪽 하단
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/









/*
import 'package:flutter/material.dart';
import 'table_widget.dart';            // 테이블 UI 위젯
import 'order_widget.dart';            // 주문 UI 위젯
import 'reservation_widget.dart';      // 예약 관리 UI 위젯 추가
import 'models.dart';                  // 데이터 모델 클래스
import 'server_service.dart';          // 서버 통신 기능

/// 앱의 실행 시작점
void main() {
  runApp(const POSApp());
}

/// 앱 전체를 감싸는 메인 위젯
class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System', // 앱 제목
      theme: ThemeData(primarySwatch: Colors.blue), // 테마 색상 설정
      home: POSHomePage(), // 메인 페이지
    );
  }
}

/// 메인 페이지의 상태 관리
class POSHomePage extends StatefulWidget {
  @override
  _POSHomePageState createState() => _POSHomePageState();
}

/// 메인 페이지의 상태 관리 클래스
class _POSHomePageState extends State<POSHomePage> {
  final List<TableModel> tables = List.generate(20, (index) => TableModel(tableNumber: index + 1, seats: 2));
  TableModel? selectedTable; // 선택된 테이블 정보
  bool hasReservation = true; // 예시: 예약이 존재한다고 가정
  final Reservation reservation = Reservation( // 예시 예약 데이터
    orderId: '12345',
    userId: 'user1',
    headcount: 4,
    menu: {'짜장면': 2, '탕수육': 1},
  );

  /// 테이블 선택 시 호출되는 함수
  void selectTable(TableModel table) {
    setState(() {
      selectedTable = table;
    });
  }

  /// 예약 수락 처리
  void acceptReservation() {
    setState(() {
      hasReservation = false; // 예약을 수락하면 숨김
    });
    print('예약 수락: ${reservation.orderId}');
  }

  /// 예약 거절 처리
  void rejectReservation() {
    setState(() {
      hasReservation = false; // 예약을 거절하면 숨김
    });
    print('예약 거절: ${reservation.orderId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // 왼쪽 영역: 테이블 목록
          Expanded(
            child: TableWidget(
              tables: tables,
              onTableSelected: selectTable,
            ),
          ),

          // 중앙 영역: 선택된 테이블의 주문 UI
          if (selectedTable != null)
            Expanded(
              child: OrderWidget(
                table: selectedTable!,
                onClearOrders: () {
                  setState(() {
                    selectedTable?.clearOrders();
                  });
                },
              ),
            ),

          // 오른쪽 하단 영역: 예약 관리 UI
          if (hasReservation)
            Expanded(
              child: ReservationWidget(
                reservation: reservation,
                onAccepted: acceptReservation, // 예약 수락 처리 함수
                onRejected: rejectReservation, // 예약 거절 처리 함수
              ),
            ),
        ],
      ),
    );
  }
}
*/






/*
import 'package:flutter/material.dart'; // Flutter UI를 만들기 위한 기본 패키지
import 'table_widget.dart';            // 테이블 목록을 표시하는 위젯 파일 가져오기
import 'order_widget.dart';            // 주문 정보를 표시하는 위젯 파일 가져오기
import 'models.dart';                  // 데이터 모델 클래스 파일 가져오기
import 'server_service.dart';          // 서버와의 통신을 담당하는 클래스 파일 가져오기

/// 앱의 실행 시작점 (entry point)
void main() {
  runApp(const POSApp()); // POSApp 클래스를 실행해 앱을 시작합니다.
}

/// 앱 전체를 감싸는 메인 위젯
/// StatelessWidget을 사용한 이유: POSApp 자체는 변경되지 않는 고정 UI를 제공
class POSApp extends StatelessWidget {
  const POSApp({super.key}); // 생성자: Flutter에서 필요한 Key를 전달받음

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System', // 앱 제목: iOS나 Android에서 표시되는 이름
      theme: ThemeData(
        primarySwatch: Colors.blue, // 앱 전체에 적용될 기본 색상 (파란색 계열)
      ),
      home: POSHomePage(), // 앱이 실행되면 보여줄 첫 번째 화면 (메인 페이지)
    );
  }
}

/// POS 시스템의 메인 페이지를 제공하는 StatefulWidget
/// StatefulWidget을 사용하는 이유: 선택된 테이블이나 주문 상태와 같은 UI 업데이트 필요
class POSHomePage extends StatefulWidget {
  @override
  _POSHomePageState createState() => _POSHomePageState(); // 상태를 관리할 State 객체 생성
}

/// _POSHomePageState 클래스
/// 메인 페이지의 상태를 관리하고 UI를 업데이트하는 역할
class _POSHomePageState extends State<POSHomePage> {
  /// 테이블 목록을 생성 (20개의 테이블, 각각 2인용)
  final List<TableModel> tables = List.generate(
    20, // 20개의 테이블 생성
    (index) => TableModel(tableNumber: index + 1, seats: 2), // 각 테이블의 번호와 좌석 수 설정
  );

  TableModel? selectedTable; // 선택된 테이블을 저장하는 변수 (초기에는 null)

  /// 테이블을 선택했을 때 호출되는 함수
  /// 선택된 테이블을 `selectedTable` 변수에 저장하고 UI를 업데이트합니다.
  void selectTable(TableModel table) {
    setState(() {
      selectedTable = table; // 선택된 테이블로 업데이트
    });
  }

  /// 선택된 테이블의 주문을 초기화하는 함수
  /// 테이블의 주문 목록을 비우고 UI를 업데이트합니다.
  void clearOrders() {
    setState(() {
      selectedTable?.clearOrders(); // 선택된 테이블의 주문 초기화
    });
  }

  /// 메인 페이지의 UI를 그리는 메서드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경색을 흰색으로 설정
      body: Row( // Row 위젯을 사용해 가로로 두 개의 영역을 나눔
        children: [
          /// 왼쪽 영역: 테이블 목록을 표시
          Expanded(
            child: TableWidget(
              tables: tables, // 테이블 목록을 전달
              onTableSelected: selectTable, // 테이블을 선택했을 때 호출될 함수 전달
            ),
          ),

          /// 오른쪽 영역: 선택된 테이블의 주문 정보를 표시
          if (selectedTable != null) // 선택된 테이블이 존재할 경우에만 표시
            Expanded(
              child: OrderWidget(
                table: selectedTable!, // 선택된 테이블 정보를 전달
                onClearOrders: clearOrders, // 주문 초기화 함수 전달
              ),
            ),
        ],
      ),
    );
  }
}
*/











/*
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POS System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black), // 수정된 부분: bodyText1 → bodyMedium
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
*/







/*
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POS System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(
          bodyText1: TextStyle(color: Colors.black), // 글씨를 검은색으로 설정
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
*/






/*
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

// MyApp 클래스는 전체 앱의 루트를 정의합니다.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS 시스템',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // 요구사항 (3): 배경 흰색
      ),
      home: const HomeScreen(), // 앱 시작 화면
    );
  }
}

*/



/*
// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter POS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(
        quickOrders: _generateQuickOrders(), // QuickOrder 데이터를 전달
      ),
    );
  }

  // QuickOrder 데이터를 생성하는 메서드
  List<Map<String, dynamic>> _generateQuickOrders() {
    return [
      {
        'orderID': '001',
        'userID': 'user123',
        'restaurantID': 'res456',
        'menu': {'Pasta': 2, 'Pizza': 1},
        'headcount': 3,
      },
      {
        'orderID': '002',
        'userID': 'user456',
        'restaurantID': 'res456',
        'menu': {'Salad': 1, 'Soda': 2},
        'headcount': 2,
      },
    ];
  }
}
*/










/*
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
*/






/*
// 의존성 문제 해결 후, 처음 코드
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS System'),
      ),
      body: SlidingUpPanel(
        minHeight: 100, // 패널의 최소 높이
        maxHeight: MediaQuery.of(context).size.height * 0.6, // 패널의 최대 높이
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
        panel: _buildPanel(), // 패널 내부 UI
        body: _buildBody(), // 메인 콘텐츠 UI
      ),
    );
  }

  // 패널 내부 UI (메뉴와 수량)
  Widget _buildPanel() {
    return ListView.builder(
      itemCount: 10, // 예시 데이터 개수
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Menu Item ${index + 1}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  // 수량 감소 로직
                },
              ),
              const Text('1'), // 수량 표시
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  // 수량 증가 로직
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 메인 화면 콘텐츠 UI (테이블 정보)
  Widget _buildBody() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 테이블 4개씩 배치
        childAspectRatio: 1.5, // 테이블 상자의 가로 세로 비율
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: 20, // 테이블 20개
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // 테이블 선택 로직
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
              child: Text(
                'Table ${index + 1}\n2인용',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        );
      },
    );
  }
}
*/



/*
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
*/
