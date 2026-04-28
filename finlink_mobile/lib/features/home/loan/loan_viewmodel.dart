import 'package:finlink_mobile/features/base_viewmodel.dart';
import 'package:finlink_mobile/models/loan/loan_models.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:finlink_mobile/services/loan/loan_service.dart';
import 'package:flutter/material.dart';

class LoanViewmodel extends BaseViewmodel {
  LoanViewmodel(this._authSession, this._loanService) {
    loadMyLoans();
  }

  final AuthSession _authSession;
  final LoanService _loanService;

  final loanFormKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final termController = TextEditingController();
  final purposeController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isLoansLoading = false;
  String? _loansError;
  List<LoanRecord> _myLoans = [];

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isLoansLoading => _isLoansLoading;
  String? get loansError => _loansError;
  List<LoanRecord> get myLoans => _myLoans;

  String? validateAmount(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(text);
    if (amount == null || amount < 5000 || amount > 50000) {
      return 'Enter an amount between 5000 and 50000';
    }
    return null;
  }

  String? validateTerm(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Term is required';
    }
    final weeks = int.tryParse(text);
    if (weeks == null || weeks < 1 || weeks > 52) {
      return 'Enter a term between 1 and 52 weeks';
    }
    return null;
  }

  Future<LoanApplicationResponse?> submit(BuildContext context) async {
    if (_isSubmitting) {
      return null;
    }

    if (!(loanFormKey.currentState?.validate() ?? false)) {
      return null;
    }

    if (!_authSession.isAuthenticated) {
      _showSnack(context, 'Please login to apply for a loan.');
      return null;
    }

    final amount = double.tryParse(amountController.text.trim());
    final termWeeks = int.tryParse(termController.text.trim());
    if (amount == null || termWeeks == null) {
      _showSnack(context, 'Please enter valid loan details.');
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _loanService.applyForLoan(
        LoanApplicationRequest(
          amount: amount,
          termWeeks: termWeeks,
          purpose: purposeController.text.trim(),
        ),
      );
      await loadMyLoans(force: true);
      return response;
    } on LoanServiceException catch (error) {
      _errorMessage = error.message;
      _showSnack(context, error.message);
      return null;
    } catch (_) {
      const message = 'Unable to submit loan request right now.';
      _errorMessage = message;
      _showSnack(context, message);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clear() {
    amountController.clear();
    termController.clear();
    purposeController.clear();
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadMyLoans({bool force = false}) async {
    if (_isLoansLoading && !force) {
      return;
    }

    _isLoansLoading = true;
    _loansError = null;
    notifyListeners();

    try {
      _myLoans = await _loanService.listMyLoans();
    } on LoanServiceException catch (error) {
      _loansError = error.message;
    } catch (_) {
      _loansError = 'Unable to load your loans right now.';
    } finally {
      _isLoansLoading = false;
      notifyListeners();
    }
  }

  void close(BuildContext context) {
    clear();
    Navigator.pop(context);
  }

  void _showSnack(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    termController.dispose();
    purposeController.dispose();
    super.dispose();
  }
}
