import 'package:flutter/material.dart'; // Flutter UI 위젯 라이브러리
import 'models.dart'; // TableModel 데이터를 가져오기 위해 사용

/// OrderWidget
/// 선택된 테이블의 정보를 표시하고 메뉴 주문 및 결제를 관리하는 위젯입니다.
class OrderWidget extends StatefulWidget {
  final TableModel table; // 선택된 테이블 정보
  final VoidCallback onClearOrders; // 주문 초기화(결제) 버튼 클릭 시 실행될 함수
  final Function(String orderDetails) onOrderPlaced; // 주문 버튼 클릭 시 실행될 함수
  final VoidCallback onOrderChanged; // 주문 상태 변경 시 호출될 함수

  const OrderWidget({
    required this.table,
    required this.onClearOrders,
    required this.onOrderPlaced,
    required this.onOrderChanged,
    super.key,
  });

  @override
  _OrderWidgetState createState() => _OrderWidgetState();
}

class _OrderWidgetState extends State<OrderWidget> {
  int steakCount = 0;
  int pastaCount = 0;
  int riceSteakCount = 0;
  int creamUdonCount = 0;
  int cokeCount = 0;

  void _incrementCount(Function(int) setter, int currentValue) {
    setState(() {
      setter(currentValue + 1);
    });
  }

  void _decrementCount(Function(int) setter, int currentValue) {
    if (currentValue > 0) {
      setState(() {
        setter(currentValue - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            '${widget.table.tableNumber}번 테이블',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildMenuItem(
          menuName: "윤씨함박스테이크정식",
          count: steakCount,
          onIncrement: () => _incrementCount((value) => steakCount = value, steakCount),
          onDecrement: () => _decrementCount((value) => steakCount = value, steakCount),
        ),
        _buildMenuItem(
          menuName: "머쉬룸투움바파스타",
          count: pastaCount,
          onIncrement: () => _incrementCount((value) => pastaCount = value, pastaCount),
          onDecrement: () => _decrementCount((value) => pastaCount = value, pastaCount),
        ),
        _buildMenuItem(
          menuName: "함박스테이크와 계란볶음밥",
          count: riceSteakCount,
          onIncrement: () => _incrementCount((value) => riceSteakCount = value, riceSteakCount),
          onDecrement: () => _decrementCount((value) => riceSteakCount = value, riceSteakCount),
        ),
        _buildMenuItem(
          menuName: "명란크림우동과 계란볶음밥",
          count: creamUdonCount,
          onIncrement: () => _incrementCount((value) => creamUdonCount = value, creamUdonCount),
          onDecrement: () => _decrementCount((value) => creamUdonCount = value, creamUdonCount),
        ),
        _buildMenuItem(
          menuName: "코카콜라",
          count: cokeCount,
          onIncrement: () => _incrementCount((value) => cokeCount = value, cokeCount),
          onDecrement: () => _decrementCount((value) => cokeCount = value, cokeCount),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLargeButton(
              text: '주문',
              onPressed: () {
                // 1개 이상인 메뉴만 주문 내역에 포함
                final List<String> orderList = [];
                if (steakCount > 0) orderList.add("윤씨함박스테이크정식: $steakCount개");
                if (pastaCount > 0) orderList.add("머쉬룸투움바파스타: $pastaCount개");
                if (riceSteakCount > 0) orderList.add("함박스테이크와 계란볶음밥: $riceSteakCount개");
                if (creamUdonCount > 0) orderList.add("명란크림우동과 계란볶음밥: $creamUdonCount개");
                if (cokeCount > 0) orderList.add("코카콜라: $cokeCount개");

                final orderDetails = orderList.join(", ");

                if (orderDetails.isNotEmpty) {
                  widget.onOrderPlaced(orderDetails); // 주문 내역 전달
                  setState(() {
                    widget.table.hasOrders = true; // 테이블 점유 상태 설정
                    widget.table.orderDetails = orderDetails; // 주문 내역 저장
                  });
                  widget.onOrderChanged(); // 서버 업데이트
                }
              },
            ),
            const SizedBox(width: 10),
            _buildLargeButton(
              text: '결제',
              onPressed: () {
                final tableNumber = widget.table.tableNumber;
                widget.onClearOrders(); // 주문 초기화
                setState(() {
                  widget.table.hasOrders = false; // 테이블 점유 상태 초기화
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "$tableNumber번 테이블의 결제가 완료되었습니다.",
                        style: const TextStyle(
                          fontSize: 24, // 글씨 크기
                          fontWeight: FontWeight.bold, // 굵은 글씨
                        ),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                });
                widget.onOrderChanged(); // 서버 업데이트
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String menuName,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              menuName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Row(
            children: [
              _buildCountButton(icon: Icons.remove, onPressed: onDecrement),
              SizedBox(
                width: 50,
                child: Center(
                  child: Text(
                    "$count",
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildCountButton(icon: Icons.add, onPressed: onIncrement),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: Colors.black,
      ),
    );
  }

  Widget _buildLargeButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: 180,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}











/*
import 'package:flutter/material.dart'; // Flutter UI 위젯 라이브러리
import 'models.dart'; // TableModel 데이터를 가져오기 위해 사용

/// OrderWidget
/// 선택된 테이블의 정보를 표시하고 메뉴 주문 및 결제를 관리하는 위젯입니다.
class OrderWidget extends StatefulWidget {
  final TableModel table; // 선택된 테이블 정보
  final VoidCallback onClearOrders; // 주문 초기화(결제) 버튼 클릭 시 실행될 함수
  final Function(String orderDetails) onOrderPlaced; // 주문 버튼 클릭 시 실행될 함수

  const OrderWidget({
    required this.table,
    required this.onClearOrders,
    required this.onOrderPlaced,
    super.key,
  });

  @override
  _OrderWidgetState createState() => _OrderWidgetState();
}

class _OrderWidgetState extends State<OrderWidget> {
  int steakCount = 0;
  int pastaCount = 0;
  int riceSteakCount = 0;
  int creamUdonCount = 0;
  int cokeCount = 0;

  void _incrementCount(Function(int) setter, int currentValue) {
    setState(() {
      setter(currentValue + 1);
    });
  }

  void _decrementCount(Function(int) setter, int currentValue) {
    if (currentValue > 0) {
      setState(() {
        setter(currentValue - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            '${widget.table.tableNumber}번 테이블',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildMenuItem(
          menuName: "윤씨함박스테이크정식",
          count: steakCount,
          onIncrement: () => _incrementCount((value) => steakCount = value, steakCount),
          onDecrement: () => _decrementCount((value) => steakCount = value, steakCount),
        ),
        _buildMenuItem(
          menuName: "머쉬룸투움바파스타",
          count: pastaCount,
          onIncrement: () => _incrementCount((value) => pastaCount = value, pastaCount),
          onDecrement: () => _decrementCount((value) => pastaCount = value, pastaCount),
        ),
        _buildMenuItem(
          menuName: "함박스테이크와 계란볶음밥",
          count: riceSteakCount,
          onIncrement: () => _incrementCount((value) => riceSteakCount = value, riceSteakCount),
          onDecrement: () => _decrementCount((value) => riceSteakCount = value, riceSteakCount),
        ),
        _buildMenuItem(
          menuName: "명란크림우동과 계란볶음밥",
          count: creamUdonCount,
          onIncrement: () => _incrementCount((value) => creamUdonCount = value, creamUdonCount),
          onDecrement: () => _decrementCount((value) => creamUdonCount = value, creamUdonCount),
        ),
        _buildMenuItem(
          menuName: "코카콜라",
          count: cokeCount,
          onIncrement: () => _incrementCount((value) => cokeCount = value, cokeCount),
          onDecrement: () => _decrementCount((value) => cokeCount = value, cokeCount),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLargeButton(
              text: '주문',
              onPressed: () {
                // 1개 이상인 메뉴만 주문 내역에 포함
                final List<String> orderList = [];
                if (steakCount > 0) {
                  orderList.add("윤씨함박스테이크정식: $steakCount개");
                }
                if (pastaCount > 0) {
                  orderList.add("머쉬룸투움바파스타: $pastaCount개");
                }
                if (riceSteakCount > 0) {
                  orderList.add("함박스테이크와 계란볶음밥: $riceSteakCount개");
                }
                if (creamUdonCount > 0) {
                  orderList.add("명란크림우동과 계란볶음밥: $creamUdonCount개");
                }
                if (cokeCount > 0) {
                  orderList.add("코카콜라: $cokeCount개");
                }

                // 주문 내역을 문자열로 결합
                final orderDetails = orderList.join(", ");

                if (orderDetails.isNotEmpty) {
                  // 주문 내역 전달
                  widget.onOrderPlaced(orderDetails);
                  setState(() {
                    widget.table.hasOrders = true; // 테이블 점유 상태로 설정
                    widget.table.orderDetails = orderDetails; // 주문 내역 저장
                  });
                }
              },
            ),
            const SizedBox(width: 10),
            _buildLargeButton(
              text: '결제',
              onPressed: () {
                // 주문 초기화 및 결제 완료 메시지 표시
                setState(() {
                  final tableNumber = widget.table.tableNumber; // 테이블 번호 저장
                  widget.onClearOrders(); // 주문 내역 초기화
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "$tableNumber번 테이블의 결제가 완료되었습니다.",
                        style: const TextStyle(
                        fontSize: 24, // 글씨 크기를 18로 설정
                        fontWeight: FontWeight.bold, // 굵은 글씨로 설정
                        ),
                      ),
                      duration: const Duration(seconds: 3), // 메시지 표시 시간
                    ),
                  );
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String menuName,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              menuName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Row(
            children: [
              _buildCountButton(icon: Icons.remove, onPressed: onDecrement),
              SizedBox(
                width: 50,
                child: Center(
                  child: Text(
                    "$count",
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildCountButton(icon: Icons.add, onPressed: onIncrement),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: Colors.black,
      ),
    );
  }

  Widget _buildLargeButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: 180,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
*/











/*
import 'package:flutter/material.dart'; // Flutter UI 위젯 라이브러리
import 'models.dart'; // TableModel 데이터를 가져오기 위해 사용

/// OrderWidget
/// 선택된 테이블의 정보를 표시하고 메뉴 주문 및 결제를 관리하는 위젯입니다.
class OrderWidget extends StatefulWidget {
  final TableModel table; // 선택된 테이블 정보
  final VoidCallback onClearOrders; // 주문 초기화(결제) 버튼 클릭 시 실행될 함수
  final Function(String orderDetails) onOrderPlaced; // 주문 버튼 클릭 시 실행될 함수

  const OrderWidget({
    required this.table,
    required this.onClearOrders,
    required this.onOrderPlaced,
    super.key,
  });

  @override
  _OrderWidgetState createState() => _OrderWidgetState();
}

class _OrderWidgetState extends State<OrderWidget> {
  // 각 메뉴의 수량을 관리하는 변수
  int steakCount = 0; // 윤씨함박스테이크정식
  int pastaCount = 0; // 머쉬룸투움바파스타
  int riceSteakCount = 0; // 함박스테이크와 계란볶음밥
  int creamUdonCount = 0; // 명란크림우동과 계란볶음밥
  int cokeCount = 0; // 코카콜라

  /// 수량 증가 메서드
  void _incrementCount(Function(int) setter, int currentValue) {
    setState(() {
      setter(currentValue + 1);
    });
  }

  /// 수량 감소 메서드
  void _decrementCount(Function(int) setter, int currentValue) {
    if (currentValue > 0) {
      setState(() {
        setter(currentValue - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start, // 상단에 배치
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// 테이블 번호를 화면 상단에 크게 표시
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            '${widget.table.tableNumber}번 테이블',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 10),

        /// 각 메뉴와 수량 선택
        _buildMenuItem(
          menuName: "윤씨함박스테이크정식",
          count: steakCount,
          onIncrement: () => _incrementCount((value) => steakCount = value, steakCount),
          onDecrement: () => _decrementCount((value) => steakCount = value, steakCount),
        ),
        _buildMenuItem(
          menuName: "머쉬룸투움바파스타",
          count: pastaCount,
          onIncrement: () => _incrementCount((value) => pastaCount = value, pastaCount),
          onDecrement: () => _decrementCount((value) => pastaCount = value, pastaCount),
        ),
        _buildMenuItem(
          menuName: "함박스테이크와 계란볶음밥",
          count: riceSteakCount,
          onIncrement: () => _incrementCount((value) => riceSteakCount = value, riceSteakCount),
          onDecrement: () => _decrementCount((value) => riceSteakCount = value, riceSteakCount),
        ),
        _buildMenuItem(
          menuName: "명란크림우동과 계란볶음밥",
          count: creamUdonCount,
          onIncrement: () => _incrementCount((value) => creamUdonCount = value, creamUdonCount),
          onDecrement: () => _decrementCount((value) => creamUdonCount = value, creamUdonCount),
        ),
        _buildMenuItem(
          menuName: "코카콜라",
          count: cokeCount,
          onIncrement: () => _incrementCount((value) => cokeCount = value, cokeCount),
          onDecrement: () => _decrementCount((value) => cokeCount = value, cokeCount),
        ),

        const SizedBox(height: 20),

        /// 주문 및 결제 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLargeButton(
              text: '주문',
              onPressed: () {
                final orderDetails =
                    "윤씨함박스테이크정식: $steakCount개, 머쉬룸투움바파스타: $pastaCount개, "
                    "함박스테이크와 계란볶음밥: $riceSteakCount개, 명란크림우동과 계란볶음밥: $creamUdonCount개, 코카콜라: $cokeCount개";
                widget.onOrderPlaced(orderDetails);
              },
            ),
            const SizedBox(width: 10),
            _buildLargeButton(
              text: '결제',
              onPressed: () {
                widget.onClearOrders();
              },
            ),
          ],
        ),
      ],
    );
  }

  /// 메뉴 아이템을 표시하는 위젯
  Widget _buildMenuItem({
    required String menuName,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              menuName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Row(
            children: [
              _buildCountButton(icon: Icons.remove, onPressed: onDecrement),
              SizedBox(
                width: 50,
                child: Center(
                
                child: Text(
                  "$count",
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                ),
              ),
              _buildCountButton(icon: Icons.add, onPressed: onIncrement),
            ],
          ),
        ],
      ),
    );
  }

  /// 수량 조절 버튼에 검은색 테두리를 추가하는 위젯
  Widget _buildCountButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black), // 검은색 테두리 추가
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: Colors.black,
      ),
    );
  }

  /// 주문 및 결제 버튼을 크게 만드는 위젯
  Widget _buildLargeButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: 180,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
*/












/*
import 'package:flutter/material.dart'; // Flutter UI 위젯 라이브러리
import 'models.dart'; // TableModel 데이터를 가져오기 위해 사용

/// OrderWidget
/// 선택된 테이블의 정보를 표시하고 메뉴 주문 및 결제를 관리하는 위젯입니다.
class OrderWidget extends StatefulWidget {
  final TableModel table; // 선택된 테이블 정보
  final VoidCallback onClearOrders; // 주문 초기화(결제) 버튼 클릭 시 실행될 함수
  final Function(String orderDetails) onOrderPlaced; // 주문 버튼 클릭 시 실행될 함수

  const OrderWidget({
    required this.table,
    required this.onClearOrders,
    required this.onOrderPlaced,
    super.key,
  });

  @override
  _OrderWidgetState createState() => _OrderWidgetState();
}

/// _OrderWidgetState
/// OrderWidget의 상태를 관리하는 클래스입니다.
class _OrderWidgetState extends State<OrderWidget> {
  int steakCount = 0; // 기본 수량
  int pastaCount = 0; // 기본 수량

  void _incrementCount(Function(int) setter, int currentValue) {
    setState(() {
      setter(currentValue + 1);
    });
  }

  void _decrementCount(Function(int) setter, int currentValue) {
    if (currentValue > 0) {
      setState(() {
        setter(currentValue - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start, // 모든 내용이 상단에 표시되도록 설정
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// 테이블 번호를 화면 상단에 크게 표시
        Padding(
          padding: const EdgeInsets.only(top: 10.0), // 상단 여백 최소화
          child: Text(
            '${widget.table.tableNumber}번 테이블',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 10),

        /// 메뉴 이름과 수량 조절 버튼
        _buildMenuItem(
          menuName: "윤씨함박스테이크정식",
          count: steakCount,
          onIncrement: () => _incrementCount((value) => steakCount = value, steakCount),
          onDecrement: () => _decrementCount((value) => steakCount = value, steakCount),
        ),
        _buildMenuItem(
          menuName: "머쉬룸투움바파스타",
          count: pastaCount,
          onIncrement: () => _incrementCount((value) => pastaCount = value, pastaCount),
          onDecrement: () => _decrementCount((value) => pastaCount = value, pastaCount),
        ),

        const SizedBox(height: 20), // 여백 조정

        /// 주문 및 결제 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLargeButton(
              text: '주문',
              onPressed: () {
                final orderDetails =
                    "윤씨함박스테이크정식: $steakCount개, 머쉬룸투움바파스타: $pastaCount개";
                widget.onOrderPlaced(orderDetails);
              },
            ),
            const SizedBox(width: 10), // 버튼 간격 최소화
            _buildLargeButton(
              text: '결제',
              onPressed: () {
                final totalAmount = (steakCount * 15000) + (pastaCount * 12000);
                widget.onClearOrders(); // 주문 초기화
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("결제 완료"),
                    content: Text(
                      "${widget.table.tableNumber}번 테이블의 결제가 완료되었습니다.\n총 금액: $totalAmount원",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("확인"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  /// 메뉴 아이템을 표시하는 위젯
  Widget _buildMenuItem({
    required String menuName,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0), // 여백 최소화
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              menuName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: onDecrement,
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  "$count",
                  style: const TextStyle(fontSize: 20),
                ),
                IconButton(
                  onPressed: onIncrement,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 주문 및 결제 버튼을 더 크게 만드는 위젯
  Widget _buildLargeButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: 180,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
*/











/*
import 'package:flutter/material.dart'; // Flutter UI 위젯 라이브러리
import 'models.dart'; // TableModel 데이터를 가져오기 위해 사용

/// OrderWidget
/// 선택된 테이블의 정보를 표시하고 메뉴 주문 및 결제를 관리하는 위젯입니다.
class OrderWidget extends StatefulWidget {
  final TableModel table; // 선택된 테이블 정보
  final VoidCallback onClearOrders; // 주문 초기화(결제) 버튼 클릭 시 실행될 함수
  final Function(String orderDetails) onOrderPlaced; // 주문 버튼 클릭 시 실행될 함수

  const OrderWidget({
    required this.table,
    required this.onClearOrders,
    required this.onOrderPlaced,
    super.key,
  });

  @override
  _OrderWidgetState createState() => _OrderWidgetState();
}

/// _OrderWidgetState
/// OrderWidget의 상태를 관리하는 클래스입니다.
class _OrderWidgetState extends State<OrderWidget> {
  // 각 메뉴의 수량을 관리하는 변수
  int steakCount = 0; // 기본 수량을 0으로 설정
  int pastaCount = 0; // 기본 수량을 0으로 설정

  /// 수량 증가 메서드
  void _incrementCount(Function(int) setter, int currentValue) {
    setState(() {
      setter(currentValue + 1);
    });
  }

  /// 수량 감소 메서드
  void _decrementCount(Function(int) setter, int currentValue) {
    if (currentValue > 0) {
      setState(() {
        setter(currentValue - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        /// 테이블 번호를 화면 상단 중앙에 크게 표시
        Center(
          child: Text(
            '${widget.table.tableNumber}번 테이블', // 테이블 번호
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 10), // 여백

        /// 메뉴 이름과 수량 조절 버튼 표시
        _buildMenuItem(
          menuName: "윤씨함박스테이크정식",
          count: steakCount,
          onIncrement: () => _incrementCount((value) => steakCount = value, steakCount),
          onDecrement: () => _decrementCount((value) => steakCount = value, steakCount),
        ),
        const SizedBox(height: 10), // 메뉴 간의 여백 (좁혀줌)
        _buildMenuItem(
          menuName: "머쉬룸투움바파스타",
          count: pastaCount,
          onIncrement: () => _incrementCount((value) => pastaCount = value, pastaCount),
          onDecrement: () => _decrementCount((value) => pastaCount = value, pastaCount),
        ),

        const SizedBox(height: 20), // 여백

        /// 주문 및 결제 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLargeButton(
              text: '주문',
              onPressed: () {
                // 주문 버튼 클릭 시
                final orderDetails =
                    "윤씨함박스테이크정식: $steakCount개, 머쉬룸투움바파스타: $pastaCount개";
                widget.onOrderPlaced(orderDetails);
              },
            ),
            const SizedBox(width: 20), // 버튼 간 여백
            _buildLargeButton(
              text: '결제',
              onPressed: () {
                // 결제 버튼 클릭 시
                final totalAmount = (steakCount * 15000) + (pastaCount * 12000);
                widget.onClearOrders(); // 주문 초기화
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("결제 완료"),
                    content: Text(
                      "${widget.table.tableNumber}번 테이블의 결제가 완료되었습니다.\n총 금액: $totalAmount원",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("확인"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  /// 메뉴 아이템을 표시하는 위젯
  Widget _buildMenuItem({
    required String menuName,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(8.0), // 패딩 조정
      margin: const EdgeInsets.symmetric(horizontal: 16.0), // 메뉴 간격 좁힘
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black), // 테두리 추가
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2, // 메뉴 이름을 더 크게 만듦
            child: Text(
              menuName,
              style: const TextStyle(
                fontSize: 20, // 글자 크기 확대
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: onDecrement,
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  "$count", // 수량 표시
                  style: const TextStyle(fontSize: 20),
                ),
                IconButton(
                  onPressed: onIncrement,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 주문 및 결제 버튼을 더 크게 만드는 위젯
  Widget _buildLargeButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: 180, // 버튼 가로 3배 확대
      height: 80, // 버튼 세로 2배 확대
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent, // 버튼 배경색
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20, // 버튼 텍스트 크기 확대
          ),
        ),
      ),
    );
  }
}
*/









/*
import 'package:flutter/material.dart'; // Flutter UI 위젯 라이브러리
import 'models.dart'; // TableModel 데이터를 가져오기 위해 사용

/// OrderWidget
/// 선택된 테이블의 정보를 표시하고 메뉴 주문 및 결제를 관리하는 위젯입니다.
class OrderWidget extends StatefulWidget {
  final TableModel table; // 선택된 테이블 정보
  final VoidCallback onClearOrders; // 주문 초기화(결제) 버튼 클릭 시 실행될 함수
  final Function(String orderDetails) onOrderPlaced; // 주문 버튼 클릭 시 실행될 함수

  const OrderWidget({
    required this.table,
    required this.onClearOrders,
    required this.onOrderPlaced,
    super.key,
  });

  @override
  _OrderWidgetState createState() => _OrderWidgetState();
}

/// _OrderWidgetState
/// OrderWidget의 상태를 관리하는 클래스입니다.
class _OrderWidgetState extends State<OrderWidget> {
  // 각 메뉴의 수량을 관리하는 변수
  int steakCount = 1; // 윤씨함박스테이크정식 초기 수량
  int pastaCount = 1; // 머쉬룸투움바파스타 초기 수량

  /// 수량 증가 메서드
  void _incrementCount(Function(int) setter, int currentValue) {
    setState(() {
      setter(currentValue + 1);
    });
  }

  /// 수량 감소 메서드
  void _decrementCount(Function(int) setter, int currentValue) {
    if (currentValue > 0) {
      setState(() {
        setter(currentValue - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// (1) 테이블 번호를 화면 상단 중앙에 크게 표시
        Center(
          child: Text(
            '${widget.table.tableNumber}번 테이블', // 테이블 번호
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 20), // 여백

        /// (2) 메뉴 이름과 수량 조절 버튼 표시
        _buildMenuItem(
          menuName: "윤씨함박스테이크정식",
          count: steakCount,
          onIncrement: () => _incrementCount((value) => steakCount = value, steakCount),
          onDecrement: () => _decrementCount((value) => steakCount = value, steakCount),
        ),
        _buildMenuItem(
          menuName: "머쉬룸투움바파스타",
          count: pastaCount,
          onIncrement: () => _incrementCount((value) => pastaCount = value, pastaCount),
          onDecrement: () => _decrementCount((value) => pastaCount = value, pastaCount),
        ),

        const SizedBox(height: 20), // 여백

        /// (3) 주문 및 결제 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // (4) 주문 버튼: 주문 내역을 테이블 박스에 전달
                final orderDetails =
                    "윤씨함박스테이크정식: $steakCount개, 머쉬룸투움바파스타: $pastaCount개";
                widget.onOrderPlaced(orderDetails); // 주문 내역 전달
              },
              child: const Text('주문'),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                // (5) 결제 버튼: 총 금액 표시 및 결제 완료 메시지
                final totalAmount = (steakCount * 15000) + (pastaCount * 12000);
                widget.onClearOrders(); // 주문 초기화
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("결제 완료"),
                    content: Text(
                      "${widget.table.tableNumber}번 테이블의 결제가 완료되었습니다.\n총 금액: $totalAmount원",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("확인"),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('결제'),
            ),
          ],
        ),
      ],
    );
  }

  /// 메뉴 아이템을 표시하는 위젯
  Widget _buildMenuItem({
    required String menuName,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            menuName, // 메뉴 이름
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: onDecrement, // 수량 감소
                icon: const Icon(Icons.remove),
              ),
              Text(
                "$count", // 수량 표시
                style: const TextStyle(fontSize: 16),
              ),
              IconButton(
                onPressed: onIncrement, // 수량 증가
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
*/











/*
import 'package:flutter/material.dart'; // Flutter UI 위젯 라이브러리
import 'models.dart'; // TableModel 데이터를 가져오기 위해 사용

/// OrderWidget
/// 선택된 테이블의 정보를 표시하고 주문을 결제(초기화)하는 위젯입니다.
class OrderWidget extends StatefulWidget {
  final TableModel table; // 선택된 테이블 정보
  final VoidCallback onClearOrders; // 주문 초기화(결제) 버튼 클릭 시 실행될 함수

  /// 생성자: 필수 인자 table과 onClearOrders를 받아옵니다.
  const OrderWidget({
    required this.table, // 테이블 정보
    required this.onClearOrders, // 주문 초기화 콜백 함수
    super.key, // Flutter 위젯 키 (선택적)
  });

  /// 상태 관리가 필요한 위젯이므로 StatefulWidget을 사용합니다.
  @override
  _OrderWidgetState createState() => _OrderWidgetState();
}

/// _OrderWidgetState
/// OrderWidget의 상태를 관리하는 클래스입니다.
class _OrderWidgetState extends State<OrderWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 자식 위젯을 왼쪽 정렬
      children: [
        /// 테이블 번호를 표시하는 텍스트 위젯
        Text(
          '${widget.table.tableNumber}번 테이블', // 테이블 번호 표시
          style: const TextStyle(
            fontSize: 20, // 글씨 크기
            fontWeight: FontWeight.bold, // 글씨를 굵게 설정
            color: Colors.black, // 텍스트 색상: 검정색
          ),
        ),

        /// 테이블 번호와 결제 버튼 사이의 여백
        const SizedBox(height: 10), // 위젯 간 세로 간격을 10픽셀로 설정

        /// 결제 버튼
        ElevatedButton(
          onPressed: widget.onClearOrders, // 버튼 클릭 시 콜백 함수 호출
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent, // 버튼의 배경색을 빨간색으로 설정
          ),
          child: const Text(
            '결제', // 버튼에 표시될 텍스트
            style: TextStyle(
              color: Colors.white, // 버튼 텍스트 색상: 흰색
              fontSize: 16, // 텍스트 크기
            ),
          ),
        ),
      ],
    );
  }
}
*/