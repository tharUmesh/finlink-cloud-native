import 'package:finlink_mobile/features/base_viewmodel.dart';
import 'package:finlink_mobile/models/loan/loan_models.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:finlink_mobile/services/loan/loan_service.dart';
import 'package:flutter/material.dart';

class CommunityViewmodel extends BaseViewmodel {
  CommunityViewmodel(this._authSession, this._loanService);

  final AuthSession _authSession;
  final LoanService _loanService;

  bool _isLoading = false;
  bool _isFunding = false;
  String? _errorMessage;
  String? _fundingLoanId;
  List<LoanRecord> _openLoans = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<LoanRecord> get openLoans => _openLoans;

  bool isFundingLoan(String loanId) =>
      _isFunding && _fundingLoanId != null && _fundingLoanId == loanId;

  Future<void> loadOpenLoans({bool force = false}) async {
    if (_isLoading && !force) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _openLoans = await _loanService.listOpenLoans();
    } on LoanServiceException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load loan requests right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> fundLoan(BuildContext context, LoanRecord loan) async {
    if (_isFunding) {
      return false;
    }

    final lenderId = _authSession.user?.id;
    if (lenderId == null || lenderId.isEmpty) {
      _showSnack(context, 'Please login to fund a loan.');
      return false;
    }

    _isFunding = true;
    _fundingLoanId = loan.id;
    notifyListeners();

    try {
      await _loanService.fundLoan(
        loan.id,
        FundLoanRequest(lenderUserId: lenderId),
      );
      _showSnack(context, 'Loan funded successfully.');
      await loadOpenLoans(force: true);
      return true;
    } on LoanServiceException catch (error) {
      _showSnack(context, error.message);
      return false;
    } catch (_) {
      _showSnack(context, 'Unable to fund this loan right now.');
      return false;
    } finally {
      _isFunding = false;
      _fundingLoanId = null;
      notifyListeners();
    }
  }

  void _showSnack(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
