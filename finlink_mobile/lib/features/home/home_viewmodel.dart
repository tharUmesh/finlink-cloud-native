import 'package:finlink_mobile/features/base_viewmodel.dart';

class HomeViewmodel extends BaseViewmodel {
	int _selectedIndex = 0;

	int get selectedIndex => _selectedIndex;

	void onTabChanged(int index) {
		if (_selectedIndex == index) {
			return;
		}
		_selectedIndex = index;
		notifyListeners();
	}
}