import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_customer/features/service/domain/selection.dart';

/// Holds the quantities and the hire start chosen on a service page.
class SelectionCubit extends Cubit<Selection> {
  /// Creates the cubit with [initial] quantities.
  SelectionCubit([Map<String, int> initial = const {}])
    : super(Selection(items: initial));

  /// Sets the quantity of [subServiceId]; zero removes it.
  void quantity(String subServiceId, int quantity) {
    final items = {...state.items}..remove(subServiceId);
    if (quantity > 0) items[subServiceId] = quantity;
    _items(items);
  }

  /// Picks one duty for a hire, replacing any other (C44).
  void only(String subServiceId, int quantity) =>
      _items({subServiceId: quantity});

  /// Sets the hire start date (a Dhaka calendar day).
  void day(DateTime day) =>
      emit(Selection(items: state.items, day: day, minutes: state.minutes));

  /// Sets the hire start time, minutes after midnight in Dhaka.
  void time(int minutes) =>
      emit(Selection(items: state.items, day: state.day, minutes: minutes));

  void _items(Map<String, int> items) =>
      emit(Selection(items: items, day: state.day, minutes: state.minutes));
}
