import 'package:google_maps_flutter/google_maps_flutter.dart';

List<LatLng> decodePolyline(String encoded) {
  var index = 0;
  var lat = 0;
  var lng = 0;
  final coordinates = <LatLng>[];

  while (index < encoded.length) {
    final latChunk = _decodeChunk(encoded, index);
    index = latChunk.nextIndex;
    lat += latChunk.value;

    final lngChunk = _decodeChunk(encoded, index);
    index = lngChunk.nextIndex;
    lng += lngChunk.value;

    coordinates.add(LatLng(lat / 1e5, lng / 1e5));
  }

  return coordinates;
}

({int nextIndex, int value}) _decodeChunk(String encoded, int startIndex) {
  var index = startIndex;
  var result = 0;
  var shift = 0;
  var byte = 0;

  do {
    byte = encoded.codeUnitAt(index++) - 63;
    result |= (byte & 0x1f) << shift;
    shift += 5;
  } while (byte >= 0x20);

  return (
    nextIndex: index,
    value: result.isOdd ? ~(result >> 1) : result >> 1,
  );
}
