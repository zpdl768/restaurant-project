/// 데이터 모델을 정의하는 파일입니다.

/// 테이블 데이터를 관리하는 클래스
/// 
/*
class TableModel {
  final int tableNumber; // 테이블 번호를 저장
  final int seats;       // 테이블의 좌석 수를 저장
  bool hasOrders = false; // 주문이 존재하는지 여부를 나타냄
  List<OrderModel> orders = []; // 테이블에 등록된 주문 목록

  /// 생성자를 통해 테이블 번호와 좌석 수를 초기화
  TableModel({required this.tableNumber, required this.seats});

  /// 테이블에 주문을 추가하는 메서드
  void addOrder(OrderModel order) {
    orders.add(order); // 주문 목록에 새로운 주문을 추가
    hasOrders = true;  // 주문이 존재함을 표시
  }
*/

/*
class TableModel {
  final int tableNumber; // 테이블 번호
  final int seats; // 테이블 좌석 수
  bool hasOrders; // 주문 여부 (true: 주문 있음, false: 주문 없음)

  TableModel({
    required this.tableNumber,
    required this.seats,
    this.hasOrders = false, // 기본값: false
  });

  /// 주문 초기화 메서드
  void clearOrders() {
    hasOrders = false;
  }
}
*/

class TableModel {
  final int tableNumber; // 테이블 번호
  final int seats; // 좌석 수
  bool hasOrders; // 주문 여부
  String orderDetails; // 주문 내역 (추가됨)

  TableModel({
    required this.tableNumber,
    required this.seats,
    this.hasOrders = false,
    this.orderDetails = "", // 초기 주문 내역은 빈 문자열
  });

  void clearOrders() {
    hasOrders = false;
    orderDetails = ""; // 주문 내역 초기화
  }
}

/// 메뉴 주문 데이터를 관리하는 클래스
class OrderModel {
  final String menuName; // 메뉴 이름
  int quantity;          // 주문 수량

  /// 생성자를 통해 메뉴 이름과 수량을 초기화
  OrderModel({required this.menuName, this.quantity = 1});
}

class Order {
  final String userId;
  final String restaurantId;
  final int headcount;
  final List<Menu> menus; // 메뉴 리스트로 수정

  Order({
    required this.userId,
    required this.restaurantId,
    required this.headcount,
    required this.menus,
  });
  
  
  
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      userId: json['user_ID'] as String,
      restaurantId: json['restaurant_ID'] as String,
      headcount: json['headcount'] as int,
      menus: (json['menus'] as List<dynamic>)
          .map((menuJson) => Menu.fromJson(menuJson))
          .toList(),
    );
  }
  
}

class Menu {
  final String name;
  final int quantity;

  Menu({
    required this.name,
    required this.quantity,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      name: json['menu'] as String,
      quantity: json['quantity'] as int,
    );
  }
}







/*
class Order {
  final String userId;
  final String restaurantId;
  final int headcount;
  final Map<String, int> menu; // 메뉴와 수량을 저장하는 Map

  Order({
    required this.userId,
    required this.restaurantId,
    required this.headcount,
    required this.menu, // 생성자에 메뉴 추가
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      userId: json['user_ID'] as String,
      restaurantId: json['restaurant_ID'] as String,
      headcount: json['headcount'] as int,
      menu: {
        if (json['menu1'] != null) 'menu1': json['menu1'] as int,
        if (json['menu2'] != null) 'menu2': json['menu2'] as int,
        if (json['menu3'] != null) 'menu3': json['menu3'] as int,
        if (json['menu4'] != null) 'menu4': json['menu4'] as int,
        if (json['menu5'] != null) 'menu5': json['menu5'] as int,
      }, // JSON 데이터를 Map으로 변환
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_ID': userId,
      'restaurant_ID': restaurantId,
      'headcount': headcount,
      ...menu, // 메뉴 데이터를 JSON으로 직렬화
    };
  }
}
*/





/*
class Order {
  final String userId;
  final String restaurantId;
  final int headcount;
  final int? menu1;
  final int? menu2;
  final int? menu3;
  final int? menu4;
  final int? menu5;

  Order({
    required this.userId,
    required this.restaurantId,
    required this.headcount,
    this.menu1,
    this.menu2,
    this.menu3,
    this.menu4,
    this.menu5,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      userId: json['user_ID'] as String,
      restaurantId: json['restaurant_ID'] as String,
      headcount: json['headcount'] as int,
      menu1: json['menu1'] as int?,
      menu2: json['menu2'] as int?,
      menu3: json['menu3'] as int?,
      menu4: json['menu4'] as int?,
      menu5: json['menu5'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_ID': userId,
      'restaurant_ID': restaurantId,
      'headcount': headcount,
      'menu1': menu1,
      'menu2': menu2,
      'menu3': menu3,
      'menu4': menu4,
      'menu5': menu5,
    };
  }
}
*/






/*
/// 예약 정보를 관리하는 클래스
class Reservation {
  final String orderId; // 주문 ID
  final String userId;  // 사용자 ID
  final String restaurantId;   // 레스토랑 ID
  final int headcount;  // 인원 수
  final Map<String, int> menu; // 메뉴와 그 수량을 저장하는 맵

  /// 생성자를 통해 예약 정보를 초기화
  Reservation({
    required this.orderId,
    required this.userId,
    required this.restaurantId, // 필수 파라미터로 추가
    required this.headcount,
    required this.menu,
  });

  String toString() {
    return '인원: $headcount, 메뉴: $menu';
  }
}
*/


