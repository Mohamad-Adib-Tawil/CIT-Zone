import 'package:flutter_bloc/flutter_bloc.dart';

/// Presentation selection only. Eligibility and persistence belong to the API.
class RatingSelectionCubit extends Cubit<int?> {
  RatingSelectionCubit({int? initial}) : super(_validate(initial));

  void select(int value) => emit(_validate(value));

  static int? _validate(int? value) {
    if (value != null && (value < 1 || value > 5)) {
      throw RangeError.range(value, 1, 5, 'rating');
    }
    return value;
  }
}
