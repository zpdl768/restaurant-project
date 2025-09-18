import 'package:flutter/material.dart';
import 'models.dart'; // 테이블 데이터 모델 클래스

class TableWidget extends StatefulWidget {
  final List<TableModel> tables; // 테이블 목록 데이터
  final Function(TableModel) onTableSelected; // 테이블 선택 시 호출되는 콜백 함수

  const TableWidget({
    required this.tables,
    required this.onTableSelected,
    super.key,
  });

  @override
  _TableWidgetState createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  // 테이블에 표시할 주문 내역을 저장하는 맵 (테이블 번호 -> 주문 내역)
  final Map<int, String> tableOrders = {};
  int? selectedTableNumber; // 현재 선택된 테이블 번호
  /// 테이블에 주문 내역을 추가하는 메서드
  void updateOrder(int tableNumber, String orderDetails) {
    setState(() {
      tableOrders[tableNumber] = orderDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 테이블 목록 (GridView)
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, // (17) 가로에 5개 테이블 배치
              mainAxisSpacing: 8.0, // 세로 간격
              crossAxisSpacing: 8.0, // 가로 간격
              childAspectRatio: 1.0, // 정사각형 비율
            ),
            itemCount: widget.tables.length,
            itemBuilder: (context, index) {
              final table = widget.tables[index];
              final isSelected = selectedTableNumber == table.tableNumber;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedTableNumber = table.tableNumber;
                  });
                  widget.onTableSelected(table);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: table.hasOrders
                        ? Colors.orangeAccent // 점유된 상태: 주황색 배경
                        : Colors.white, // 비어있는 상태: 흰색 배경
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.black, // 선택 여부에 따라 테두리 색상 변경
                      width: isSelected ? 5.0 : 1.0, // 선택된 테두리는 두껍게
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // (18) 테이블 번호와 좌석 수 (중앙 상단)
                      Text(
                        '${table.tableNumber}번 (${table.seats}인용)',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Spacer(), // 위쪽과 아래를 구분하는 여백
                      // (19) 주문 내역 표시
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          table.orderDetails.isNotEmpty
                              ? table.orderDetails // 주문 내역 표시
                              : "", // 기본 메시지
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        /*// (20) 테이블 정보 수정 버튼
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: () {
                // 화면 이동: 테이블 정보 수정 화면으로 (임시 동작)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const Placeholder()), // 화면 이동을 임시 Placeholder로 구현
                );
              },
              child: const Text(
                "테이블 정보 수정",
                style: TextStyle(fontSize: 16),
                
              ),
            ),
          ),
        ),*/
      ],
    );
  }
}










/*
import 'package:flutter/material.dart';
import 'models.dart'; // 테이블 데이터 모델 클래스

class TableWidget extends StatefulWidget {
  final List<TableModel> tables; // 테이블 목록 데이터
  final Function(TableModel) onTableSelected; // 테이블 선택 시 호출되는 콜백 함수

  const TableWidget({
    required this.tables,
    required this.onTableSelected,
    super.key,
  });

  @override
  _TableWidgetState createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  // 테이블에 표시할 주문 내역을 저장하는 맵 (테이블 번호 -> 주문 내역)
  final Map<int, String> tableOrders = {};

  /// 테이블에 주문 내역을 추가하는 메서드
  void updateOrder(int tableNumber, String orderDetails) {
    setState(() {
      tableOrders[tableNumber] = orderDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 테이블 목록 (GridView)
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, // (17) 가로에 5개 테이블 배치
              mainAxisSpacing: 8.0, // 세로 간격
              crossAxisSpacing: 8.0, // 가로 간격
              childAspectRatio: 1.0, // 정사각형 비율
            ),
            itemCount: widget.tables.length,
            itemBuilder: (context, index) {
              final table = widget.tables[index];
              return GestureDetector(
                onTap: () => widget.onTableSelected(table), // 테이블 선택 콜백 호출
                child: Container(
                  decoration: BoxDecoration(
                    color: table.hasOrders
                        ? Colors.orangeAccent // 점유된 상태: 주황색 배경
                        : Colors.white, // 비어있는 상태: 흰색 배경
                    border: Border.all(color: Colors.black), // 검은색 테두리
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // (18) 테이블 번호와 좌석 수 (중앙 상단)
                      Text(
                        '${table.tableNumber}번 (${table.seats}인용)',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Spacer(), // 위쪽과 아래를 구분하는 여백
                      // (19) 주문 내역 표시
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          table.orderDetails.isNotEmpty
                              ? table.orderDetails // 주문 내역 표시
                              : "", // 기본 메시지
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        /*// (20) 테이블 정보 수정 버튼
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: () {
                // 화면 이동: 테이블 정보 수정 화면으로 (임시 동작)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const Placeholder()), // 화면 이동을 임시 Placeholder로 구현
                );
              },
              child: const Text(
                "테이블 정보 수정",
                style: TextStyle(fontSize: 16),
                
              ),
            ),
          ),
        ),*/
      ],
    );
  }
}
*/











/*
import 'package:flutter/material.dart'; // Flutter UI를 구성하는 기본 패키지
import 'models.dart'; // 테이블 모델 클래스를 불러옵니다.

/// 테이블 목록을 화면에 표시하는 위젯
/// 각 테이블을 Grid 형태로 보여주며, 테이블을 선택할 수 있습니다.
class TableWidget extends StatelessWidget {
  final List<TableModel> tables; // 테이블 정보를 담고 있는 리스트
  final Function(TableModel) onTableSelected; // 테이블을 선택했을 때 실행될 콜백 함수

  /// 생성자: 테이블 목록과 선택 콜백을 인자로 받습니다.
  const TableWidget({
    required this.tables, // 테이블 리스트
    required this.onTableSelected, // 테이블 선택 시 실행할 함수
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0), // GridView의 외부 여백 설정
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // 한 행에 표시될 테이블의 수 (4개)
        mainAxisSpacing: 8.0, // 행 사이의 간격
        crossAxisSpacing: 8.0, // 열 사이의 간격
      ),
      itemCount: tables.length, // Grid에 표시될 항목(테이블)의 총 개수
      itemBuilder: (context, index) {
        // 현재 index에 해당하는 테이블 가져오기
        final table = tables[index];

        return GestureDetector(
          // 테이블을 터치했을 때 실행되는 콜백 함수
          onTap: () => onTableSelected(table),

          /// 테이블 정보를 표시하는 컨테이너
          child: Container(
            decoration: BoxDecoration(
              color: table.hasOrders
                  ? Colors.orangeAccent // 주문이 존재하면 배경색을 주황색으로 설정
                  : Colors.white, // 주문이 없으면 배경색을 흰색으로 설정
              border: Border.all(color: Colors.black), // 테두리 색상을 검정색으로 설정
              borderRadius: BorderRadius.circular(8.0), // 모서리를 둥글게 만듦
            ),
            child: Center(
              /// 테이블 번호와 좌석 수를 표시하는 텍스트
              child: Text(
                '${table.tableNumber}번\n(${table.seats}인용)', // 테이블 번호와 인원 수를 표시
                style: const TextStyle(
                  color: Colors.black, // 텍스트 색상은 검정색
                  fontSize: 16, // 텍스트 크기
                  fontWeight: FontWeight.bold, // 텍스트를 굵게 표시
                ),
                textAlign: TextAlign.center, // 텍스트를 중앙 정렬
              ),
            ),
          ),
        );
      },
    );
  }
}
*/


