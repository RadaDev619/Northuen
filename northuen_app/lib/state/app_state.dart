import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cash_report_model.dart';
import '../models/driver_model.dart';
import '../models/notification_model.dart';
import '../models/order_model.dart';
import '../models/pickdrop_model.dart';
import '../models/product_model.dart';
import '../models/tracking_point_model.dart';
import '../models/user_model.dart';
import '../models/vendor_model.dart';
import '../models/wallet_model.dart';
import '../services/api_client.dart';
import 'cart_state.dart';

class AppState extends ChangeNotifier {
  AppState(this.api);

  final ApiClient api;
  AppUser? user;
  bool loading = false;
  String? error;
  List<Vendor> vendors = [];
  List<Product> products = [];
  List<Order> orders = [];
  List<Order> assignedOrders = [];
  List<Order> availableDriverOrders = [];
  List<PickDropOrder> pickDropOrders = [];
  List<PickDropOrder> availablePickDropOrders = [];
  List<PickDropOrder> assignedPickDropOrders = [];
  DriverLiveLocation? pickDropLiveLocation;
  List<PickDropMessage> pickDropMessages = [];
  PickDropContact? pickDropContact;
  PickDropCallSession? activePickDropCall;
  IncomingPickDropCall? incomingPickDropCall;
  List<Driver> drivers = [];
  List<AppUser> users = [];
  CashReport? cashReport;
  WalletAccount? wallet;
  List<TrackingPoint> trackingPoints = [];
  List<AppNotification> notifications = [];
  int unreadNotifications = 0;

  bool get authenticated => user != null;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    api.token = prefs.getString('token');
    if (api.token == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      user = AppUser.fromJson(await api.get('/api/auth/me'));
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await prefs.remove('token');
        api.token = null;
        user = null;
      } else {
        error = e.toString();
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    await _auth('/api/auth/login', {'email': email, 'password': password});
  }

  Future<void> register(
    String fullName,
    String email,
    String phone,
    String password,
    String role,
  ) async {
    await _auth('/api/auth/register', {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    });
  }

  Future<void> _auth(String path, Map<String, dynamic> body) async {
    await _run(() async {
      final json = await api.post(path, body);
      api.token = json['token'];
      user = AppUser.fromJson(json['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', api.token!);
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    api.token = null;
    user = null;
    orders = [];
    assignedOrders = [];
    pickDropOrders = [];
    availablePickDropOrders = [];
    assignedPickDropOrders = [];
    pickDropMessages = [];
    pickDropContact = null;
    activePickDropCall = null;
    incomingPickDropCall = null;
    wallet = null;
    notifications = [];
    unreadNotifications = 0;
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    await _run(() async {
      notifications = (await api.get('/api/notifications') as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
      unreadNotifications = notifications.where((item) => !item.read).length;
    });
  }

  Future<List<AppNotification>> refreshNotificationsQuietly() async {
    if (!authenticated) return const [];
    try {
      final next = (await api.get('/api/notifications') as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
      notifications = next;
      unreadNotifications = next.where((item) => !item.read).length;
      notifyListeners();
      return next;
    } catch (_) {
      return notifications;
    }
  }

  Future<void> markNotificationRead(String id) async {
    await _run(() async {
      final updated = AppNotification.fromJson(
        await api.patch('/api/notifications/$id/read', {}),
      );
      notifications = [
        updated,
        ...notifications.where((item) => item.id != updated.id),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      unreadNotifications = notifications.where((item) => !item.read).length;
    });
  }

  Future<void> sendAdminNotification({
    required String title,
    required String message,
    required String targetMode,
    String? role,
    String? userId,
    String type = 'ADMIN',
    int priority = 0,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'broadcast': targetMode == 'ALL',
    };
    if (targetMode == 'ROLE') body['role'] = role;
    if (targetMode == 'USER') body['userId'] = userId;
    await _run(() async => api.post('/api/admin/notifications', body));
  }

  Future<void> loadWallet() async {
    await _run(
      () async =>
          wallet = WalletAccount.fromJson(await api.get('/api/wallet/me')),
    );
  }

  Future<void> loadVendors({String? query, String? category}) async {
    final params = <String>[];
    if (query != null && query.trim().isNotEmpty) {
      params.add('q=${Uri.encodeQueryComponent(query.trim())}');
    }
    if (category != null && category != 'ALL') {
      params.add('category=${Uri.encodeQueryComponent(category)}');
    }
    final suffix = params.isEmpty ? '' : '?${params.join('&')}';
    await _run(
      () async => vendors = (await api.get('/api/vendors$suffix') as List)
          .map((json) => Vendor.fromJson(json))
          .toList(),
    );
  }

  Future<void> loadProducts(String vendorId) async {
    await _run(
      () async =>
          products = (await api.get('/api/vendors/$vendorId/products') as List)
              .map((json) => Product.fromJson(json))
              .toList(),
    );
  }

  Future<void> addBackendCartItem(String productId, int quantity) async {
    await api.post('/api/cart/items', {
      'productId': productId,
      'quantity': quantity,
    });
  }

  Future<void> loadOrders() async {
    await _run(
      () async => orders = (await api.get('/api/orders/my') as List)
          .map((json) => Order.fromJson(json))
          .toList(),
    );
  }

  Future<void> loadTracking(String orderId) async {
    await _run(
      () async => trackingPoints =
          (await api.get('/api/orders/$orderId/tracking') as List)
              .map((json) => TrackingPoint.fromJson(json))
              .toList(),
    );
  }

  void setTrackingPoints(List<TrackingPoint> points) {
    trackingPoints = points;
    notifyListeners();
  }

  void addTrackingPoint(TrackingPoint point) {
    trackingPoints = [
      point,
      ...trackingPoints.where((existing) => existing.id != point.id),
    ];
    notifyListeners();
  }

  Future<void> reviewOrder(
    String orderId,
    int vendorRating,
    int driverRating,
    String comment,
  ) async {
    await _run(
      () async => api.post('/api/orders/$orderId/review', {
        'vendorRating': vendorRating,
        'driverRating': driverRating,
        'comment': comment,
      }),
    );
  }

  Future<Order> createShopOrder(
    CartState cart,
    String dropoffAddress,
    String notes,
  ) async {
    final json = await api.post('/api/orders', {
      'orderType': cart.vendor!.category == 'SHOP' ? 'SHOP' : 'FOOD',
      'vendorId': cart.vendor!.id,
      'items': cart.lines
          .map(
            (line) => {'productId': line.product.id, 'quantity': line.quantity},
          )
          .toList(),
      'pickupAddress': cart.vendor!.address,
      'dropoffAddress': dropoffAddress,
      'deliveryFee': cart.deliveryFee,
      'notes': notes,
    });
    final order = Order.fromJson(json);
    cart.clear();
    await loadOrders();
    return order;
  }

  Future<Order> createParcel(
    String pickup,
    String dropoff,
    String description,
    String notes,
  ) async {
    final json = await api.post('/api/orders', {
      'orderType': 'PARCEL',
      'pickupAddress': pickup,
      'dropoffAddress': dropoff,
      'parcelDescription': description,
      'deliveryFee': 80,
      'notes': notes,
    });
    final order = Order.fromJson(json);
    await loadOrders();
    return order;
  }

  Future<PickDropFare?> estimatePickDropFare({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  }) async {
    try {
      return PickDropFare.fromJson(
        await api.post('/api/pickdrop/fare', {
          'pickupLat': pickupLat,
          'pickupLng': pickupLng,
          'dropLat': dropLat,
          'dropLng': dropLng,
        }),
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<PickDropOrder> createPickDropOrder({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String dropAddress,
    required double dropLat,
    required double dropLng,
    required String itemType,
    required String itemDescription,
  }) async {
    final order = PickDropOrder.fromJson(
      await api.post('/api/pickdrop/orders', {
        'pickupAddress': pickupAddress,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropAddress': dropAddress,
        'dropLat': dropLat,
        'dropLng': dropLng,
        'itemType': itemType,
        'itemDescription': itemDescription,
      }),
    );
    await loadPickDropOrders();
    return order;
  }

  Future<void> loadPickDropOrders() async {
    await _run(
      () async =>
          pickDropOrders = (await api.get('/api/pickdrop/orders/my') as List)
              .map((json) => PickDropOrder.fromJson(json))
              .toList(),
    );
  }

  Future<PickDropOrder> refreshPickDropOrder(String orderId) async {
    final order = PickDropOrder.fromJson(
      await api.get('/api/pickdrop/orders/$orderId'),
    );
    pickDropOrders = [
      order,
      ...pickDropOrders.where((existing) => existing.id != order.id),
    ];
    notifyListeners();
    return order;
  }

  Future<void> loadPickDropDriverWork() async {
    await _run(() async {
      availablePickDropOrders =
          (await api.get('/api/pickdrop/driver/available') as List)
              .map((json) => PickDropOrder.fromJson(json))
              .toList();
      assignedPickDropOrders =
          (await api.get('/api/pickdrop/driver/mine') as List)
              .map((json) => PickDropOrder.fromJson(json))
              .toList();
    });
  }

  Future<bool> acceptPickDrop(String orderId) async {
    final accepted = await _run(
      () async => api.patch('/api/pickdrop/driver/orders/$orderId/accept', {}),
    );
    if (accepted) await loadPickDropDriverWork();
    return accepted;
  }

  Future<bool> rejectPickDrop(String orderId) async {
    final rejected = await _run(
      () async => api.patch('/api/pickdrop/driver/orders/$orderId/reject', {}),
    );
    if (rejected) await loadPickDropDriverWork();
    return rejected;
  }

  Future<PickDropOrder?> updatePickDropStatus(
    String orderId,
    String status,
  ) async {
    PickDropOrder? updated;
    await _run(() async {
      updated = PickDropOrder.fromJson(
        await api.patch('/api/pickdrop/driver/orders/$orderId/status', {
          'status': status,
        }),
      );
    });
    await loadPickDropDriverWork();
    return updated;
  }

  Future<DriverLiveLocation> sendPickDropLocation(
    String orderId,
    double lat,
    double lng, {
    double? heading,
    double? speed,
  }) async {
    final body = <String, dynamic>{'lat': lat, 'lng': lng};
    if (heading != null) body['heading'] = heading;
    if (speed != null) body['speed'] = speed;
    final json = await api.post(
      '/api/pickdrop/driver/orders/$orderId/location',
      body,
    );
    pickDropLiveLocation = DriverLiveLocation.fromJson(json);
    notifyListeners();
    return pickDropLiveLocation!;
  }

  Future<void> completePickDrop(String orderId) async {
    await _run(
      () async =>
          api.patch('/api/pickdrop/driver/orders/$orderId/complete', {}),
    );
    await loadPickDropDriverWork();
  }

  Future<DriverLiveLocation?> loadPickDropLiveLocation(String orderId) async {
    try {
      final json = await api.get('/api/pickdrop/orders/$orderId/live-location');
      pickDropLiveLocation = json == null
          ? null
          : DriverLiveLocation.fromJson(json);
      notifyListeners();
      return pickDropLiveLocation;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> loadPickDropMessages(String orderId) async {
    try {
      pickDropMessages =
          (await api.get('/api/pickdrop/orders/$orderId/messages') as List)
              .map((json) => PickDropMessage.fromJson(json))
              .toList();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<PickDropMessage?> sendPickDropMessage(
    String orderId,
    String body,
  ) async {
    try {
      final message = PickDropMessage.fromJson(
        await api.post('/api/pickdrop/orders/$orderId/messages', {
          'body': body,
        }),
      );
      pickDropMessages = [
        ...pickDropMessages.where((existing) => existing.id != message.id),
        message,
      ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
      return message;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void addPickDropMessage(PickDropMessage message) {
    pickDropMessages = [
      ...pickDropMessages.where((existing) => existing.id != message.id),
      message,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();
  }

  Future<PickDropContact?> loadPickDropContact(String orderId) async {
    try {
      pickDropContact = PickDropContact.fromJson(
        await api.get('/api/pickdrop/orders/$orderId/contact'),
      );
      notifyListeners();
      return pickDropContact;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<PickDropCallSession?> startPickDropCall(String orderId) async {
    final json = await api.post('/api/pickdrop/orders/$orderId/calls', {});
    activePickDropCall = PickDropCallSession.fromJson(json);
    notifyListeners();
    return activePickDropCall;
  }

  Future<PickDropCallSession?> loadActivePickDropCall(String orderId) async {
    final json = await api.get('/api/pickdrop/orders/$orderId/calls/active');
    activePickDropCall = json == null
        ? null
        : PickDropCallSession.fromJson(json);
    notifyListeners();
    return activePickDropCall;
  }

  Future<IncomingPickDropCall?> loadIncomingPickDropCall() async {
    if (!authenticated) return null;
    try {
      final json = await api.get('/api/pickdrop/calls/incoming');
      incomingPickDropCall = json == null
          ? null
          : IncomingPickDropCall.fromJson(json);
      notifyListeners();
      return incomingPickDropCall;
    } catch (_) {
      incomingPickDropCall = null;
      notifyListeners();
      return null;
    }
  }

  Future<void> endPickDropCall(String callId) async {
    final json = await api.patch('/api/pickdrop/calls/$callId/end', {});
    activePickDropCall = PickDropCallSession.fromJson(json);
    notifyListeners();
  }

  Future<List<PickDropCallSignal>> loadPickDropCallSignals(
    String callId,
  ) async {
    return (await api.get('/api/pickdrop/calls/$callId/signals') as List)
        .map((json) => PickDropCallSignal.fromJson(json))
        .toList();
  }

  Future<void> sendPickDropCallSignal(
    String callId,
    String type,
    String payload,
  ) async {
    await api.post('/api/pickdrop/calls/$callId/signals', {
      'type': type,
      'payload': payload,
    });
  }

  Future<void> loadAssignedOrders() async {
    await _run(
      () async => assignedOrders =
          (await api.get('/api/drivers/assigned-orders') as List)
              .map((json) => Order.fromJson(json))
              .toList(),
    );
  }

  Future<void> loadAvailableDriverOrders() async {
    await _run(
      () async => availableDriverOrders =
          (await api.get('/api/drivers/available-orders') as List)
              .map((json) => Order.fromJson(json))
              .toList(),
    );
  }

  Future<void> loadDriverWork() async {
    await _run(() async {
      availableDriverOrders =
          (await api.get('/api/drivers/available-orders') as List)
              .map((json) => Order.fromJson(json))
              .toList();
      assignedOrders = (await api.get('/api/drivers/assigned-orders') as List)
          .map((json) => Order.fromJson(json))
          .toList();
    });
  }

  Future<bool> acceptAvailableDelivery(String deliveryId) async {
    final accepted = await _run(
      () async =>
          api.patch('/api/drivers/available-orders/$deliveryId/accept', {}),
    );
    if (accepted) await loadDriverWork();
    return accepted;
  }

  Future<void> setDriverAvailable(bool value) async => _run(
    () async => api.patch('/api/drivers/availability', {'available': value}),
  );

  Future<void> updateDelivery(String deliveryId, String status) async {
    await _run(
      () async =>
          api.patch('/api/deliveries/$deliveryId/status', {'status': status}),
    );
    await loadDriverWork();
  }

  Future<void> sendLocation(
    String deliveryId,
    double latitude,
    double longitude,
  ) async {
    await api.post('/api/deliveries/$deliveryId/location', {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<void> completeDelivery(String deliveryId) async {
    await _run(
      () async => api.patch('/api/deliveries/$deliveryId/complete', {}),
    );
    await loadDriverWork();
  }

  Future<void> loadAdmin() async {
    await _run(() async {
      orders = (await api.get('/api/admin/orders') as List)
          .map((json) => Order.fromJson(json))
          .toList();
      drivers = (await api.get('/api/admin/drivers') as List)
          .map((json) => Driver.fromJson(json))
          .toList();
      users = (await api.get('/api/admin/users') as List)
          .map((json) => AppUser.fromJson(json))
          .toList();
      cashReport = CashReport.fromJson(await api.get('/api/admin/cash-report'));
    });
  }

  Future<void> assignDriver(String orderId, String driverId) async {
    await _run(
      () async => api.patch('/api/admin/orders/$orderId/assign-driver', {
        'driverId': driverId,
      }),
    );
    await loadAdmin();
  }

  Future<void> saveVendor(Map<String, dynamic> body) async =>
      _run(() async => api.put('/api/vendor/profile', body));

  Future<void> saveProduct(Map<String, dynamic> body, {String? id}) async {
    await _run(() async {
      if (id == null) {
        await api.post('/api/vendor/products', body);
      } else {
        await api.put('/api/vendor/products/$id', body);
      }
    });
  }

  Future<void> loadVendorProducts() async {
    await _run(
      () async => products = (await api.get('/api/vendor/products') as List)
          .map((json) => Product.fromJson(json))
          .toList(),
    );
  }

  Future<void> loadVendorOrders() async {
    await _run(
      () async => orders = (await api.get('/api/vendor/orders') as List)
          .map((json) => Order.fromJson(json))
          .toList(),
    );
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _run(
      () async => api.patch('/api/orders/$orderId/status', {'status': status}),
    );
  }

  Future<bool> _run(Future<void> Function() task) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await task();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
