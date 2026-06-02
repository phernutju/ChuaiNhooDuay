import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';

class RequesterState {
  final RequestType? selectedCategory;
  final String description;
  final UrgencyLevel urgency;
  final GeoPoint? coordinates;
  final String locationAddress;
  final bool isAnonymous;
  final bool isLocationLoading;
  final bool isSubmitting;
  final String? error;

  const RequesterState({
    this.selectedCategory,
    this.description = '',
    this.urgency = UrgencyLevel.general,
    this.coordinates,
    this.locationAddress = '',
    this.isAnonymous = false,
    this.isLocationLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  RequesterState copyWith({
    RequestType? selectedCategory,
    String? description,
    UrgencyLevel? urgency,
    GeoPoint? coordinates,
    String? locationAddress,
    bool? isAnonymous,
    bool? isLocationLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return RequesterState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      description: description ?? this.description,
      urgency: urgency ?? this.urgency,
      coordinates: coordinates ?? this.coordinates,
      locationAddress: locationAddress ?? this.locationAddress,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isLocationLoading: isLocationLoading ?? this.isLocationLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }

  bool get canSubmit =>
      selectedCategory != null && coordinates != null && !isSubmitting;
}

class RequesterController extends StateNotifier<RequesterState> {
  final RequestService _service;

  RequesterController(this._service) : super(const RequesterState());

  void selectCategory(RequestType category) =>
      state = state.copyWith(selectedCategory: category);

  void setDescription(String desc) =>
      state = state.copyWith(description: desc);

  void setUrgency(UrgencyLevel level) =>
      state = state.copyWith(urgency: level);

  void toggleAnonymous() =>
      state = state.copyWith(isAnonymous: !state.isAnonymous);

  Future<void> fetchCurrentLocation() async {
    state = state.copyWith(isLocationLoading: true, error: null);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLocationLoading: false,
          error: 'Location services disabled',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLocationLoading: false,
          error: 'Location permission denied',
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      state = state.copyWith(
        coordinates: GeoPoint(pos.latitude, pos.longitude),
        locationAddress:
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
        isLocationLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLocationLoading: false, error: e.toString());
    }
  }

  Future<int> submitRequest() async {
    if (!state.canSubmit) throw Exception('Category and location required');

    state = state.copyWith(isSubmitting: true, error: null);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final cred = await FirebaseAuth.instance.signInAnonymously();
        user = cred.user!;
      }

      final now = DateTime.now();
      final request = RequestModel(
        id: '',
        createdBy: user.uid,
        title: state.selectedCategory == RequestType.other &&
                state.description.isNotEmpty
            ? state.description.split('\n').first
            : _categoryTitle(state.selectedCategory!),
        description: state.description,
        location: RequestLocation(
          address: state.locationAddress,
          coordinates: state.coordinates!,
        ),
        requestType: state.selectedCategory!,
        urgencyLevel: state.urgency,
        urgencyScore: _urgencyScore(state.urgency),
        maxVolunteer: 5,
        status: RequestStatus.waiting,
        isAnonymous: state.isAnonymous,
        createdAt: now,
        updatedAt: now,
      );

      final requestId = await _service.createRequest(request);
      final count =
          await _service.notifyNearbyVolunteers(requestId, state.coordinates!);
      state = state.copyWith(isSubmitting: false);
      return count;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      rethrow;
    }
  }

  void reset() => state = const RequesterState();

  String _categoryTitle(RequestType type) => switch (type) {
        RequestType.medical => 'Medical assistance needed',
        RequestType.shelter => 'Shelter needed',
        RequestType.water => 'Water / Food needed',
        RequestType.transport => 'Transport / Ride needed',
        RequestType.rescue => 'Rescue needed',
        RequestType.evacuate => 'Evacuation needed',
        RequestType.supplies => 'Supplies needed',
        RequestType.other => 'Help needed',
      };

  int _urgencyScore(UrgencyLevel level) => switch (level) {
        UrgencyLevel.critical => 100,
        UrgencyLevel.urgent => 60,
        UrgencyLevel.general => 20,
      };
}

final requesterControllerProvider =
    StateNotifierProvider<RequesterController, RequesterState>(
  (ref) => RequesterController(RequestService()),
);

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final myRequestsProvider =
    StreamProvider.family<List<RequestModel>, String>((ref, requesterId) {
  return RequestService().getMyRequests(requesterId);
});

final openRequestsProvider = StreamProvider<List<RequestModel>>((ref) {
  return RequestService().getOpenRequests();
});
