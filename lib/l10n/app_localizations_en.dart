// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get signIn => 'Sign in';

  @override
  String helloUser(String name) {
    return 'Hello, $name';
  }

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get enterPasswordToContinue => 'Enter your password to continue.';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get createAccount => 'Create account';

  @override
  String get welcome => 'Welcome';

  @override
  String get fillDetailsToStart =>
      'Fill in your details to start using the app.';

  @override
  String get nameLabel => 'Name *';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get lastName => 'Last name';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get businessName => 'Business name';

  @override
  String get currencyLabel => 'Currency *';

  @override
  String get passwordLabel => 'Password *';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get confirmPasswordLabel => 'Confirm password *';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get failedToCreateAccount => 'Failed to create account.';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get updateDetailsBelow => 'Update your account details below.';

  @override
  String get nameFieldLabel => 'Name';

  @override
  String get nameRequiredDot => 'Name is required.';

  @override
  String get currencyFieldLabel => 'Currency';

  @override
  String get couldNotUpdateProfile => 'Could not update profile.';

  @override
  String get profileUpdatedRelogin => 'Profile updated. Please log in again.';

  @override
  String get profileUpdated => 'Profile updated.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get confirmCurrentPasswordPrompt =>
      'Confirm your current password to set a new one.';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get currentPasswordRequired => 'Current password is required.';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get newPasswordRequired => 'New password is required.';

  @override
  String get newPasswordMinLength =>
      'Password must be at least 6 characters long.';

  @override
  String get confirmNewPasswordLabel => 'Confirm new password';

  @override
  String get passwordsDoNotMatchDot => 'Passwords do not match.';

  @override
  String get couldNotChangePassword => 'Could not change password.';

  @override
  String get passwordChangedRelogin => 'Password changed. Please log in again.';

  @override
  String get passwordChanged => 'Password changed.';

  @override
  String get changePasswordButton => 'Change password';

  @override
  String get deleteCustomer => 'Delete customer';

  @override
  String confirmDeleteCustomerMessage(String name) {
    return 'Are you sure you want to delete \"$name\"? Associated sales history will be kept.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get customersTitle => 'Customers';

  @override
  String get newCustomer => 'New customer';

  @override
  String get noCustomersYet => 'No customers registered yet.';

  @override
  String get editCustomer => 'Edit customer';

  @override
  String get notesLabel => 'Notes';

  @override
  String get createCustomer => 'Create customer';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get hello => 'Hello';

  @override
  String get salesDoingIntro => 'Here is how your sales are doing.';

  @override
  String get finalizedSales => 'Finalized sales';

  @override
  String get totalRevenue => 'Total revenue';

  @override
  String get settledCreditSales => 'Settled credit sales';

  @override
  String get salesByCategory => 'Sales by category';

  @override
  String get noCategoriesYet => 'No categories registered yet.';

  @override
  String saleCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sales',
      one: '1 sale',
      zero: '0 sales',
    );
    return '$_temp0';
  }

  @override
  String get suppliersTitle => 'Suppliers';

  @override
  String get noSuppliersYet => 'No suppliers registered yet.';

  @override
  String get newSupplier => 'New supplier';

  @override
  String get editSupplier => 'Edit supplier';

  @override
  String get deleteSupplier => 'Delete supplier';

  @override
  String get createSupplier => 'Create supplier';

  @override
  String get addressLabel => 'Address';

  @override
  String get deleteSupplierConfirmationGeneric =>
      'Are you sure you want to delete this supplier?';

  @override
  String confirmDeleteSupplierMessage(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get newExpenseCategory => 'New Category';

  @override
  String get descriptionOptionalLabel => 'Description (optional)';

  @override
  String get filterExpensesTitle => 'Filter expenses';

  @override
  String get categoryLabel => 'Category';

  @override
  String get allLabel => 'All';

  @override
  String get supplierLabel => 'Supplier';

  @override
  String get startDateLabel => 'Start date';

  @override
  String get endDateLabel => 'End date';

  @override
  String get clearLabel => 'Clear';

  @override
  String get applyLabel => 'Apply';

  @override
  String get newExpense => 'New expense';

  @override
  String get editExpense => 'Edit expense';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionRequired => 'Description is required';

  @override
  String get amountLabel => 'Amount (MZN)';

  @override
  String get amountRequired => 'Amount is required';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get supplierOptionalLabel => 'Supplier (optional)';

  @override
  String get noneLabel => 'None';

  @override
  String get pleaseSelectCategory => 'Please select a category.';

  @override
  String dateLabel(String date) {
    return 'Date: $date';
  }

  @override
  String get createExpense => 'Create expense';

  @override
  String get noCategoriesAvailableYet => 'No categories available yet.';

  @override
  String get addAtLeastOneCategory => 'Add at least one category.';

  @override
  String categoryAllocationsMismatch(String allocated, String total) {
    return 'Category allocations ($allocated) must add up to the expense total ($total).';
  }

  @override
  String get addCategoryButton => 'Add category';

  @override
  String get noCategoryAddedYet => 'No category added yet.';

  @override
  String allocatedAmountLabel(String amount) {
    return 'Allocated: $amount';
  }

  @override
  String totalAmountValueLabel(String amount) {
    return 'Total: $amount';
  }

  @override
  String get categoryAllocationDialogTitle => 'Category allocation';

  @override
  String get selectCategoryValidation => 'Select a category';

  @override
  String get saveLabel => 'Save';

  @override
  String get expensesTitle => 'Expenses';

  @override
  String get deleteExpense => 'Delete expense';

  @override
  String confirmDeleteExpenseMessage(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get deletionReasonLabel => 'Deletion reason';

  @override
  String get noExpensesYet => 'No expenses registered.';

  @override
  String get unknownCustomer => 'Unknown customer';

  @override
  String customerNumber(String id) {
    return 'Customer #$id';
  }

  @override
  String get enterValidPaymentAmount => 'Enter a valid payment amount.';

  @override
  String get paymentExceedsRemainingDebt =>
      'Payment exceeds the remaining debt.';

  @override
  String get paymentRegistered => 'Payment registered.';

  @override
  String get couldNotRegisterPayment => 'Could not register payment.';

  @override
  String get cancelSale => 'Cancel sale';

  @override
  String get cancellationReasonLabel => 'Cancellation reason';

  @override
  String get back => 'Back';

  @override
  String get cancelSaleButton => 'Cancel Sale';

  @override
  String get couldNotCancelSale => 'Could not cancel sale.';

  @override
  String get creditSaleTitle => 'Credit Sale';

  @override
  String get saleNotFound => 'Sale not found.';

  @override
  String get totalLabel => 'Total';

  @override
  String get paidSoFarLabel => 'Paid so far';

  @override
  String get remainingDebtLabel => 'Remaining debt';

  @override
  String get statusLabel => 'Status';

  @override
  String get paymentStatusLabel => 'Payment status';

  @override
  String get dueDateLabel => 'Due date';

  @override
  String get registerPayment => 'Register payment';

  @override
  String get amountFieldLabel => 'Amount';

  @override
  String get enterValidAmount => 'Enter a valid amount';

  @override
  String get paymentMethodLabel => 'Payment method';

  @override
  String get cashMethod => 'Cash';

  @override
  String get bankTransferMethod => 'Bank transfer';

  @override
  String get mpesaMethod => 'M-Pesa';

  @override
  String get emolaMethod => 'E-Mola';

  @override
  String get otherMethod => 'Other';

  @override
  String get notesOptionalLabel => 'Notes (optional)';

  @override
  String get paymentHistory => 'Payment history';

  @override
  String get noPaymentsYet => 'No payments registered yet.';

  @override
  String get creditSalesTitle => 'Credit Sales';

  @override
  String get noOutstandingCreditSales => 'No outstanding credit sales.';

  @override
  String creditSaleSubtitle(
    String reference,
    String description,
    String owed,
    String currency,
    String paid,
  ) {
    return '$reference — $description\nOwed: $owed $currency • Paid so far: $paid $currency';
  }

  @override
  String get salesGroupLabel => 'Sales';

  @override
  String get finishedSalesLabel => 'Finished Sales';

  @override
  String get categoriesLabel => 'Categories';

  @override
  String get financialStatementsLabel => 'Financial Statements';

  @override
  String get logOut => 'Log Out';

  @override
  String get changeThemeLabel => 'Change Theme';

  @override
  String get confirmLogoutTitle => 'Confirm Logout';

  @override
  String get confirmLogoutMessage => 'Are you sure you want to log out?';

  @override
  String get languageLabel => 'Language';

  @override
  String get statementDetailTitle => 'Statement Detail';

  @override
  String salesCountLabel(int count) {
    return 'Sales ($count)';
  }

  @override
  String expensesCountLabel(int count) {
    return 'Expenses ($count)';
  }

  @override
  String get balanceLabel => 'Balance';

  @override
  String get salesSectionTitle => 'Sales';

  @override
  String get noSalesInPeriod => 'No sales in this period.';

  @override
  String get expensesSectionTitle => 'Expenses';

  @override
  String get noExpensesInPeriod => 'No expenses in this period.';

  @override
  String get generateStatementTitle => 'Generate Statement';

  @override
  String get periodLabel => 'Period';

  @override
  String get selectBothDatesMessage => 'Select both a start and an end date.';

  @override
  String get endDateBeforeStartDateMessage =>
      'End date cannot be before start date.';

  @override
  String get selectStartDate => 'Select start date';

  @override
  String get selectEndDate => 'Select end date';

  @override
  String startDatePrefix(String date) {
    return 'Start: $date';
  }

  @override
  String endDatePrefix(String date) {
    return 'End: $date';
  }

  @override
  String get generateButtonLabel => 'Generate';

  @override
  String get financialStatementsTitle => 'Financial Statements';

  @override
  String get noStatementsYet => 'No statements generated yet.';

  @override
  String get deleteStatementTitle => 'Delete statement';

  @override
  String confirmDeleteStatementMessage(String name) {
    return 'Delete statement $name? This cannot be undone.';
  }

  @override
  String get couldNotDeleteStatement => 'Could not delete statement.';

  @override
  String get generateStatementTooltip => 'Generate statement';

  @override
  String generatedOnPrefix(String date) {
    return 'Generated $date';
  }

  @override
  String get newCategoryTitle => 'New Category';

  @override
  String get editCategoryTitle => 'Edit Category';

  @override
  String get nameRequiredMessage => 'Name is required';

  @override
  String get createCategoryButton => 'Create';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get addCategoryTooltip => 'Add category';

  @override
  String get deleteCategoryTitle => 'Delete category';

  @override
  String confirmDeleteCategoryMessage(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get couldNotDeleteCategory => 'Could not delete category.';

  @override
  String get newSaleTitle => 'New Sale';

  @override
  String get selectCustomerMessage => 'Select a customer.';

  @override
  String get enterWalkInNameMessage => 'Enter a walk-in customer name.';

  @override
  String get enterValidInitialPaymentMessage =>
      'Enter a valid initial payment.';

  @override
  String get initialPaymentExceedsTotalMessage =>
      'Initial payment cannot exceed the sale total.';

  @override
  String get categoryRequiredMessage => 'Category is required';

  @override
  String get descriptionRequiredMessage => 'Description is required';

  @override
  String get totalAmountLabel => 'Total amount';

  @override
  String get enterValidAmountMessage => 'Enter a valid amount';

  @override
  String get normalLabel => 'Normal';

  @override
  String get creditLabel => 'Credit';

  @override
  String get useExistingCustomerLabel => 'Use existing customer';

  @override
  String get associateExistingCustomerOptionalLabel =>
      'Associate an existing customer (optional)';

  @override
  String get customerLabel => 'Customer';

  @override
  String get walkInCustomerNameLabel => 'Walk-in customer name';

  @override
  String get addDueDateOptionalLabel => 'Add a due date (optional)';

  @override
  String dueDatePrefix(String date) {
    return 'Due: $date';
  }

  @override
  String get initialPaymentOptionalLabel => 'Initial payment (optional)';

  @override
  String get initialPaymentHelperText =>
      'Leave empty if nothing was paid yet — the full amount stays owed.';

  @override
  String get createSaleButton => 'Create Sale';

  @override
  String get finishedSalesTitle => 'Finished Sales';

  @override
  String get creditSalesTooltip => 'Credit sales';

  @override
  String get typeLabel => 'Type';

  @override
  String get noFinishedSalesYet => 'No finished sales yet.';

  @override
  String get newSaleTooltip => 'New sale';

  @override
  String get cancelSaleTitle => 'Cancel sale';

  @override
  String get backLabel => 'Back';

  @override
  String get noCustomerLabel => 'No customer';

  @override
  String customerNumberLabel(int id) {
    return 'Customer #$id';
  }

  @override
  String get immediateLabel => 'Immediate';

  @override
  String get noInstallmentsRegistered => 'No installments registered.';

  @override
  String paidInInstallmentsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'installments',
      one: 'installment',
      zero: 'installments',
    );
    return 'Paid in $count $_temp0:';
  }

  @override
  String get splashLoading => 'Preparing your experience...';

  @override
  String get categoryBreakdownSectionTitle => 'By category';

  @override
  String get noCategoryBreakdownInPeriod =>
      'No categorized activity in this period.';

  @override
  String get noCategoryLabel => 'No category';
}
