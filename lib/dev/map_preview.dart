// lib/dev/map_preview.dart — ไฟล์เทสต์ชั่วคราว
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/request_model.dart';
import '../features/map/nearby_requests_map.dart';
import '../features/map/pick_location_map.dart';
import '../utils/google_maps_loader.dart';

// แก้ main() ให้ async
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await loadGoogleMaps(dotenv.env['MAPS_API_KEY'] ?? '');
  runApp(const MaterialApp(home: MapPreview()));
}

// ที่เหลือเหมือนเดิมทุกอย่าง
RequestModel _mock(String id, String title, double lat, double lng,
    UrgencyLevel u, int max, int assigned) =>
    RequestModel(
      id: id,
      createdBy: 'tester',
      title: title,
      location: RequestLocation(address: 'mock', coordinates: GeoPoint(lat, lng)),
      requestType: RequestType.other,
      urgencyLevel: u,
      urgencyScore: 1,
      maxVolunteer: max,
      assignedVolunteerIds: List.generate(assigned, (i) => 'v$i'),
      status: RequestStatus.open,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

final mock = [
  _mock('1', 'ยกของ', 13.7563, 100.5018, UrgencyLevel.critical, 5, 0),
  _mock('2', 'ปฐมพยาบาล', 13.760, 100.510, UrgencyLevel.urgent, 3, 1),
  _mock('3', 'แจกอาหาร (เต็ม)', 13.740, 100.490, UrgencyLevel.general, 2, 2),
];

class MapPreview extends StatelessWidget {
  const MapPreview({super.key});
  @override
  Widget build(BuildContext context) {
    const center = LatLng(13.7563, 100.5018);
    return Scaffold(
      appBar: AppBar(title: const Text('Map preview')),
      body: ListView(children: [
        const Padding(padding: EdgeInsets.all(8), child: Text('NearbyRequestsMap')),
        SizedBox(
          height: 320,
          child: NearbyRequestsMap(
            center: center,
            radiusKm: 10,
            requests: mock.where((r) => !r.isFull).toList(),
            onRequestTap: (id) => debugPrint('tapped: $id'),
          ),
        ),
        const Padding(padding: EdgeInsets.all(8), child: Text('PickLocationMap')),
        SizedBox(
          height: 320,
          child: PickLocationMap(
            initialCenter: center,
            onLocationPicked: (p) => debugPrint('picked: $p'),
          ),
        ),
      ]),
    );
  }
}