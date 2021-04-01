import 'package:bloc/bloc.dart';

class BlockedUserCellCubit extends Cubit<bool> {
  BlockedUserCellCubit() : super(false);

  void setUnblockState(bool newValue) => emit(newValue);
}
