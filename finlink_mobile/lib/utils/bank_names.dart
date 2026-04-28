enum BankName {
  bankOfCeylon,
  commercialBank,
  hattonNationalBank,
  peoplesBank,
  sampathBank,
}

extension BankNameX on BankName {
  String get displayName {
    switch (this) {
      case BankName.bankOfCeylon:
        return 'Bank of Ceylon';
      case BankName.commercialBank:
        return 'Commercial Bank';
      case BankName.hattonNationalBank:
        return 'Hatton National Bank';
      case BankName.peoplesBank:
        return "People's Bank";
      case BankName.sampathBank:
        return 'Sampath Bank';
    }
  }

  String get logoAssetPath {
    switch (this) {
      case BankName.bankOfCeylon:
        return 'images/banks/boc.svg';
      case BankName.commercialBank:
        return 'images/banks/Commercial.png';
      case BankName.hattonNationalBank:
        return 'images/banks/hnb.png';
      case BankName.peoplesBank:
        return 'images/banks/peoples_bank.jpg';
      case BankName.sampathBank:
        return 'images/banks/sampath.png';
    }
  }

  bool get isSvg => logoAssetPath.toLowerCase().endsWith('.svg');
}