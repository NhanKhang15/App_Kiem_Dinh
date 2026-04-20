import 'order_model.dart';

class OrdersListResponse {
  final List<OrderModel> orders;
  final int? count;
  final Map<String, dynamic>? staff;

  OrdersListResponse({required this.orders, this.count, this.staff});

  factory OrdersListResponse.fromJson(Map<String, dynamic> json) {
    // Theo JSON mới, danh sách đơn hàng nằm trong khóa 'tasks'
    var listData = json['tasks'] as List?;
    // Fallback cho các trường hợp khác nếu có
    listData ??= json['results'] as List?;
    listData ??= json['orders'] as List?;
    
    final list = listData?.map((e) => OrderModel.fromJson(e)).toList() ?? [];
    
    return OrdersListResponse(
      orders: list,
      count: json['count'] ?? list.length,
      staff: json['staff'],
    );
  }
}
