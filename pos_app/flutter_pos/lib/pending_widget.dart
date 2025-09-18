import 'package:flutter/material.dart';
import 'models.dart'; // Reservation 모델 클래스
import 'server_service.dart'; // 서버 통신 서비스

class PendingWidget extends StatefulWidget {
  const PendingWidget({super.key});

  @override
  _PendingWidgetState createState() => _PendingWidgetState();
}

class _PendingWidgetState extends State<PendingWidget> {
  final List<Order> pendingOrders = []; // 조리 중인 주문 목록
  final serverService = ServerService(); // 서버와 통신하는 객체

  /// 수락된 주문을 추가하는 메서드
  void addOrder(Order order) {
    setState(() {
      pendingOrders.add(order);
    });
  }

  /// 조리 완료 버튼을 눌렀을 때 실행되는 메서드
  void completeOrder(int index) {
    final completedOrder = pendingOrders[index];
    setState(() {
      pendingOrders.removeAt(index); // 해당 주문 삭제
    });

    // 서버에 조리 완료 상태를 전송
    serverService.sendOrderComplete(
      completedOrder.userId,
      completedOrder.restaurantId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "조리 중인 QuickOrder 주문",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, // 가로 5개 박스
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 1.0,
            ),
            itemCount: pendingOrders.length,
            itemBuilder: (context, index) {
              final order = pendingOrders[index];
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "주문 ${index + 1}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(order.toString()), // 주문 내역 표시
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => completeOrder(index),
                      child: const Text(
                        "조리 완료",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}