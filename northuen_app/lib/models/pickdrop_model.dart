class PickDropFare {
  PickDropFare({
    required this.distanceKm,
    required this.baseFare,
    required this.perKmRate,
    required this.estimatedPrice,
  });

  final num distanceKm;
  final num baseFare;
  final num perKmRate;
  final num estimatedPrice;

  factory PickDropFare.fromJson(Map<String, dynamic> json) => PickDropFare(
    distanceKm: json['distanceKm'],
    baseFare: json['baseFare'],
    perKmRate: json['perKmRate'],
    estimatedPrice: json['estimatedPrice'],
  );
}

class PickDropOrder {
  PickDropOrder({
    required this.id,
    required this.customerId,
    this.driverId,
    this.driverName,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropAddress,
    required this.dropLat,
    required this.dropLng,
    required this.itemType,
    required this.itemDescription,
    required this.estimatedDistanceKm,
    required this.estimatedPrice,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String customerId;
  final String? driverId;
  final String? driverName;
  final String pickupAddress;
  final num pickupLat;
  final num pickupLng;
  final String dropAddress;
  final num dropLat;
  final num dropLng;
  final String itemType;
  final String itemDescription;
  final num estimatedDistanceKm;
  final num estimatedPrice;
  final String status;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PickDropOrder.fromJson(Map<String, dynamic> json) => PickDropOrder(
    id: json['id'],
    customerId: json['customerId'] ?? json['customer_id'],
    driverId: json['driverId'] ?? json['driver_id'],
    driverName: json['driverName'],
    pickupAddress: json['pickupAddress'] ?? json['pickup_address'],
    pickupLat: json['pickupLat'] ?? json['pickup_lat'],
    pickupLng: json['pickupLng'] ?? json['pickup_lng'],
    dropAddress: json['dropAddress'] ?? json['drop_address'],
    dropLat: json['dropLat'] ?? json['drop_lat'],
    dropLng: json['dropLng'] ?? json['drop_lng'],
    itemType: json['itemType'] ?? json['item_type'],
    itemDescription: json['itemDescription'] ?? json['item_description'],
    estimatedDistanceKm:
        json['estimatedDistanceKm'] ?? json['estimated_distance_km'],
    estimatedPrice: json['estimatedPrice'] ?? json['estimated_price'],
    status: json['status'],
    paymentStatus: json['paymentStatus'] ?? json['payment_status'],
    createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
    updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
  );
}

class DriverLiveLocation {
  DriverLiveLocation({
    required this.driverId,
    required this.orderId,
    required this.lat,
    required this.lng,
    this.heading,
    this.speed,
    required this.updatedAt,
  });

  final String driverId;
  final String orderId;
  final num lat;
  final num lng;
  final num? heading;
  final num? speed;
  final DateTime updatedAt;

  factory DriverLiveLocation.fromJson(Map<String, dynamic> json) =>
      DriverLiveLocation(
        driverId: json['driverId'] ?? json['driver_id'],
        orderId: json['orderId'] ?? json['order_id'],
        lat: json['lat'],
        lng: json['lng'],
        heading: json['heading'],
        speed: json['speed'],
        updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
      );
}

class PickDropMessage {
  PickDropMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String body;
  final DateTime createdAt;

  factory PickDropMessage.fromJson(Map<String, dynamic> json) =>
      PickDropMessage(
        id: json['id'],
        orderId: json['orderId'] ?? json['order_id'],
        senderId: json['senderId'] ?? json['sender_id'],
        senderName:
            json['senderName'] ?? json['sender_name'] ?? 'Northuen user',
        senderRole: json['senderRole'] ?? json['sender_role'],
        body: json['body'],
        createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      );
}

class PickDropContact {
  PickDropContact({
    required this.userId,
    required this.name,
    required this.phone,
  });

  final String userId;
  final String name;
  final String phone;

  factory PickDropContact.fromJson(Map<String, dynamic> json) =>
      PickDropContact(
        userId: json['userId'] ?? json['user_id'],
        name: json['name'],
        phone: json['phone'],
      );
}

class PickDropCallSession {
  PickDropCallSession({
    required this.id,
    required this.orderId,
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.receiverName,
    required this.status,
    required this.createdAt,
    this.endedAt,
  });

  final String id;
  final String orderId;
  final String callerId;
  final String callerName;
  final String receiverId;
  final String receiverName;
  final String status;
  final DateTime createdAt;
  final DateTime? endedAt;

  factory PickDropCallSession.fromJson(Map<String, dynamic> json) =>
      PickDropCallSession(
        id: json['id'],
        orderId: json['orderId'],
        callerId: json['callerId'],
        callerName: json['callerName'],
        receiverId: json['receiverId'],
        receiverName: json['receiverName'],
        status: json['status'],
        createdAt: DateTime.parse(json['createdAt']),
        endedAt: json['endedAt'] == null
            ? null
            : DateTime.parse(json['endedAt']),
      );
}

class IncomingPickDropCall {
  IncomingPickDropCall({required this.call, required this.order});

  final PickDropCallSession call;
  final PickDropOrder order;

  factory IncomingPickDropCall.fromJson(Map<String, dynamic> json) =>
      IncomingPickDropCall(
        call: PickDropCallSession.fromJson(json['call']),
        order: PickDropOrder.fromJson(json['order']),
      );
}

class PickDropCallSignal {
  PickDropCallSignal({
    required this.id,
    required this.callId,
    required this.senderId,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String callId;
  final String senderId;
  final String type;
  final String payload;
  final DateTime createdAt;

  factory PickDropCallSignal.fromJson(Map<String, dynamic> json) =>
      PickDropCallSignal(
        id: json['id'],
        callId: json['callId'],
        senderId: json['senderId'],
        type: json['type'],
        payload: json['payload'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}
