import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloUser(String name);

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @enterPasswordToContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to continue.'**
  String get enterPasswordToContinue;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @fillDetailsToStart.
  ///
  /// In en, this message translates to:
  /// **'Fill in your details to start using the app.'**
  String get fillDetailsToStart;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get nameLabel;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get businessName;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency *'**
  String get currencyLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password *'**
  String get passwordLabel;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password *'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @failedToCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to create account.'**
  String get failedToCreateAccount;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @updateDetailsBelow.
  ///
  /// In en, this message translates to:
  /// **'Update your account details below.'**
  String get updateDetailsBelow;

  /// No description provided for @nameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameFieldLabel;

  /// No description provided for @nameRequiredDot.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get nameRequiredDot;

  /// No description provided for @currencyFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyFieldLabel;

  /// No description provided for @couldNotUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not update profile.'**
  String get couldNotUpdateProfile;

  /// No description provided for @profileUpdatedRelogin.
  ///
  /// In en, this message translates to:
  /// **'Profile updated. Please log in again.'**
  String get profileUpdatedRelogin;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @confirmCurrentPasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Confirm your current password to set a new one.'**
  String get confirmCurrentPasswordPrompt;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPasswordLabel;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required.'**
  String get currentPasswordRequired;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @newPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'New password is required.'**
  String get newPasswordRequired;

  /// No description provided for @newPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long.'**
  String get newPasswordMinLength;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @passwordsDoNotMatchDot.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatchDot;

  /// No description provided for @couldNotChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Could not change password.'**
  String get couldNotChangePassword;

  /// No description provided for @passwordChangedRelogin.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Please log in again.'**
  String get passwordChangedRelogin;

  /// No description provided for @changePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordButton;

  /// No description provided for @deleteCustomer.
  ///
  /// In en, this message translates to:
  /// **'Delete customer'**
  String get deleteCustomer;

  /// No description provided for @confirmDeleteCustomerMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? Associated sales history will be kept.'**
  String confirmDeleteCustomerMessage(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @newCustomer.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get newCustomer;

  /// No description provided for @noCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers registered yet.'**
  String get noCustomersYet;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get editCustomer;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @createCustomer.
  ///
  /// In en, this message translates to:
  /// **'Create customer'**
  String get createCustomer;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @salesDoingIntro.
  ///
  /// In en, this message translates to:
  /// **'Here is how your sales are doing.'**
  String get salesDoingIntro;

  /// No description provided for @finalizedSales.
  ///
  /// In en, this message translates to:
  /// **'Finalized sales'**
  String get finalizedSales;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total revenue'**
  String get totalRevenue;

  /// No description provided for @settledCreditSales.
  ///
  /// In en, this message translates to:
  /// **'Settled credit sales'**
  String get settledCreditSales;

  /// No description provided for @salesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Sales by category'**
  String get salesByCategory;

  /// No description provided for @noCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories registered yet.'**
  String get noCategoriesYet;

  /// No description provided for @saleCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sale} other{{count} sales}}'**
  String saleCountLabel(int count);

  /// No description provided for @suppliersTitle.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliersTitle;

  /// No description provided for @noSuppliersYet.
  ///
  /// In en, this message translates to:
  /// **'No suppliers registered yet.'**
  String get noSuppliersYet;

  /// No description provided for @newSupplier.
  ///
  /// In en, this message translates to:
  /// **'New supplier'**
  String get newSupplier;

  /// No description provided for @editSupplier.
  ///
  /// In en, this message translates to:
  /// **'Edit supplier'**
  String get editSupplier;

  /// No description provided for @deleteSupplier.
  ///
  /// In en, this message translates to:
  /// **'Delete supplier'**
  String get deleteSupplier;

  /// No description provided for @createSupplier.
  ///
  /// In en, this message translates to:
  /// **'Create supplier'**
  String get createSupplier;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @deleteSupplierConfirmationGeneric.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this supplier?'**
  String get deleteSupplierConfirmationGeneric;

  /// No description provided for @confirmDeleteSupplierMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String confirmDeleteSupplierMessage(String name);

  /// No description provided for @newExpenseCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newExpenseCategory;

  /// No description provided for @editExpenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editExpenseCategory;

  /// No description provided for @descriptionOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptionalLabel;

  /// No description provided for @deleteExpenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get deleteExpenseCategory;

  /// No description provided for @confirmDeleteExpenseCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String confirmDeleteExpenseCategoryMessage(String name);

  /// No description provided for @failedToDeleteExpenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete category.'**
  String get failedToDeleteExpenseCategory;

  /// No description provided for @expenseCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Categories'**
  String get expenseCategoriesTitle;

  /// No description provided for @noExpenseCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.'**
  String get noExpenseCategoriesYet;

  /// No description provided for @createExpenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Create category'**
  String get createExpenseCategory;

  /// No description provided for @filterExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter expenses'**
  String get filterExpensesTitle;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @supplierLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplierLabel;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDateLabel;

  /// No description provided for @endDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDateLabel;

  /// No description provided for @clearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearLabel;

  /// No description provided for @applyLabel.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyLabel;

  /// No description provided for @newExpense.
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get newExpense;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get editExpense;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionRequired;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (MZN)'**
  String get amountLabel;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get amountRequired;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @supplierOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier (optional)'**
  String get supplierOptionalLabel;

  /// No description provided for @noneLabel.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneLabel;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category.'**
  String get pleaseSelectCategory;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateLabel(String date);

  /// No description provided for @createExpense.
  ///
  /// In en, this message translates to:
  /// **'Create expense'**
  String get createExpense;

  /// No description provided for @expensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesTitle;

  /// No description provided for @deleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete expense'**
  String get deleteExpense;

  /// No description provided for @confirmDeleteExpenseMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String confirmDeleteExpenseMessage(String name);

  /// No description provided for @deletionReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Deletion reason'**
  String get deletionReasonLabel;

  /// No description provided for @noExpensesYet.
  ///
  /// In en, this message translates to:
  /// **'No expenses registered.'**
  String get noExpensesYet;

  /// No description provided for @unknownCustomer.
  ///
  /// In en, this message translates to:
  /// **'Unknown customer'**
  String get unknownCustomer;

  /// No description provided for @customerNumber.
  ///
  /// In en, this message translates to:
  /// **'Customer #{id}'**
  String customerNumber(String id);

  /// No description provided for @enterValidPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid payment amount.'**
  String get enterValidPaymentAmount;

  /// No description provided for @paymentExceedsRemainingDebt.
  ///
  /// In en, this message translates to:
  /// **'Payment exceeds the remaining debt.'**
  String get paymentExceedsRemainingDebt;

  /// No description provided for @paymentRegistered.
  ///
  /// In en, this message translates to:
  /// **'Payment registered.'**
  String get paymentRegistered;

  /// No description provided for @couldNotRegisterPayment.
  ///
  /// In en, this message translates to:
  /// **'Could not register payment.'**
  String get couldNotRegisterPayment;

  /// No description provided for @cancelSale.
  ///
  /// In en, this message translates to:
  /// **'Cancel sale'**
  String get cancelSale;

  /// No description provided for @cancellationReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get cancellationReasonLabel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancelSaleButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Sale'**
  String get cancelSaleButton;

  /// No description provided for @couldNotCancelSale.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel sale.'**
  String get couldNotCancelSale;

  /// No description provided for @creditSaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit Sale'**
  String get creditSaleTitle;

  /// No description provided for @saleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Sale not found.'**
  String get saleNotFound;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @paidSoFarLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid so far'**
  String get paidSoFarLabel;

  /// No description provided for @remainingDebtLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining debt'**
  String get remainingDebtLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @paymentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get paymentStatusLabel;

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDateLabel;

  /// No description provided for @registerPayment.
  ///
  /// In en, this message translates to:
  /// **'Register payment'**
  String get registerPayment;

  /// No description provided for @amountFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountFieldLabel;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethodLabel;

  /// No description provided for @cashMethod.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashMethod;

  /// No description provided for @bankTransferMethod.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get bankTransferMethod;

  /// No description provided for @mpesaMethod.
  ///
  /// In en, this message translates to:
  /// **'M-Pesa'**
  String get mpesaMethod;

  /// No description provided for @emolaMethod.
  ///
  /// In en, this message translates to:
  /// **'E-Mola'**
  String get emolaMethod;

  /// No description provided for @otherMethod.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherMethod;

  /// No description provided for @notesOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptionalLabel;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get paymentHistory;

  /// No description provided for @noPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No payments registered yet.'**
  String get noPaymentsYet;

  /// No description provided for @creditSalesTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit Sales'**
  String get creditSalesTitle;

  /// No description provided for @noOutstandingCreditSales.
  ///
  /// In en, this message translates to:
  /// **'No outstanding credit sales.'**
  String get noOutstandingCreditSales;

  /// No description provided for @creditSaleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{reference} — {description}\nOwed: {owed} {currency} • Paid so far: {paid} {currency}'**
  String creditSaleSubtitle(
    String reference,
    String description,
    String owed,
    String currency,
    String paid,
  );

  /// No description provided for @salesGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesGroupLabel;

  /// No description provided for @finishedSalesLabel.
  ///
  /// In en, this message translates to:
  /// **'Finished Sales'**
  String get finishedSalesLabel;

  /// No description provided for @saleCategoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale Categories'**
  String get saleCategoriesLabel;

  /// No description provided for @financialStatementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Financial Statements'**
  String get financialStatementsLabel;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @changeThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Change Theme'**
  String get changeThemeLabel;

  /// No description provided for @confirmLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogoutTitle;

  /// No description provided for @confirmLogoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get confirmLogoutMessage;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @statementDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Statement Detail'**
  String get statementDetailTitle;

  /// No description provided for @salesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Sales ({count})'**
  String salesCountLabel(int count);

  /// No description provided for @expensesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Expenses ({count})'**
  String expensesCountLabel(int count);

  /// No description provided for @balanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balanceLabel;

  /// No description provided for @salesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesSectionTitle;

  /// No description provided for @noSalesInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No sales in this period.'**
  String get noSalesInPeriod;

  /// No description provided for @expensesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesSectionTitle;

  /// No description provided for @noExpensesInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this period.'**
  String get noExpensesInPeriod;

  /// No description provided for @generateStatementTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate Statement'**
  String get generateStatementTitle;

  /// No description provided for @periodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get periodLabel;

  /// No description provided for @selectBothDatesMessage.
  ///
  /// In en, this message translates to:
  /// **'Select both a start and an end date.'**
  String get selectBothDatesMessage;

  /// No description provided for @endDateBeforeStartDateMessage.
  ///
  /// In en, this message translates to:
  /// **'End date cannot be before start date.'**
  String get endDateBeforeStartDateMessage;

  /// No description provided for @selectStartDate.
  ///
  /// In en, this message translates to:
  /// **'Select start date'**
  String get selectStartDate;

  /// No description provided for @selectEndDate.
  ///
  /// In en, this message translates to:
  /// **'Select end date'**
  String get selectEndDate;

  /// No description provided for @startDatePrefix.
  ///
  /// In en, this message translates to:
  /// **'Start: {date}'**
  String startDatePrefix(String date);

  /// No description provided for @endDatePrefix.
  ///
  /// In en, this message translates to:
  /// **'End: {date}'**
  String endDatePrefix(String date);

  /// No description provided for @generateButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generateButtonLabel;

  /// No description provided for @financialStatementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Statements'**
  String get financialStatementsTitle;

  /// No description provided for @noStatementsYet.
  ///
  /// In en, this message translates to:
  /// **'No statements generated yet.'**
  String get noStatementsYet;

  /// No description provided for @deleteStatementTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete statement'**
  String get deleteStatementTitle;

  /// No description provided for @confirmDeleteStatementMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete statement {name}? This cannot be undone.'**
  String confirmDeleteStatementMessage(String name);

  /// No description provided for @couldNotDeleteStatement.
  ///
  /// In en, this message translates to:
  /// **'Could not delete statement.'**
  String get couldNotDeleteStatement;

  /// No description provided for @generateStatementTooltip.
  ///
  /// In en, this message translates to:
  /// **'Generate statement'**
  String get generateStatementTooltip;

  /// No description provided for @generatedOnPrefix.
  ///
  /// In en, this message translates to:
  /// **'Generated {date}'**
  String generatedOnPrefix(String date);

  /// No description provided for @newCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategoryTitle;

  /// No description provided for @editCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategoryTitle;

  /// No description provided for @nameRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequiredMessage;

  /// No description provided for @createCategoryButton.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createCategoryButton;

  /// No description provided for @saleCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sale Categories'**
  String get saleCategoriesTitle;

  /// No description provided for @noSaleCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No sale categories yet.'**
  String get noSaleCategoriesYet;

  /// No description provided for @addCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategoryTooltip;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get deleteCategoryTitle;

  /// No description provided for @confirmDeleteCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String confirmDeleteCategoryMessage(String name);

  /// No description provided for @couldNotDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Could not delete category.'**
  String get couldNotDeleteCategory;

  /// No description provided for @newSaleTitle.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSaleTitle;

  /// No description provided for @selectCustomerMessage.
  ///
  /// In en, this message translates to:
  /// **'Select a customer.'**
  String get selectCustomerMessage;

  /// No description provided for @enterWalkInNameMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a walk-in customer name.'**
  String get enterWalkInNameMessage;

  /// No description provided for @enterValidInitialPaymentMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid initial payment.'**
  String get enterValidInitialPaymentMessage;

  /// No description provided for @initialPaymentExceedsTotalMessage.
  ///
  /// In en, this message translates to:
  /// **'Initial payment cannot exceed the sale total.'**
  String get initialPaymentExceedsTotalMessage;

  /// No description provided for @categoryRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Category is required'**
  String get categoryRequiredMessage;

  /// No description provided for @descriptionRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionRequiredMessage;

  /// No description provided for @totalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get totalAmountLabel;

  /// No description provided for @enterValidAmountMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmountMessage;

  /// No description provided for @normalLabel.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normalLabel;

  /// No description provided for @creditLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get creditLabel;

  /// No description provided for @useExistingCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Use existing customer'**
  String get useExistingCustomerLabel;

  /// No description provided for @associateExistingCustomerOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Associate an existing customer (optional)'**
  String get associateExistingCustomerOptionalLabel;

  /// No description provided for @customerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerLabel;

  /// No description provided for @walkInCustomerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Walk-in customer name'**
  String get walkInCustomerNameLabel;

  /// No description provided for @addDueDateOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Add a due date (optional)'**
  String get addDueDateOptionalLabel;

  /// No description provided for @dueDatePrefix.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String dueDatePrefix(String date);

  /// No description provided for @initialPaymentOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Initial payment (optional)'**
  String get initialPaymentOptionalLabel;

  /// No description provided for @initialPaymentHelperText.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if nothing was paid yet — the full amount stays owed.'**
  String get initialPaymentHelperText;

  /// No description provided for @createSaleButton.
  ///
  /// In en, this message translates to:
  /// **'Create Sale'**
  String get createSaleButton;

  /// No description provided for @finishedSalesTitle.
  ///
  /// In en, this message translates to:
  /// **'Finished Sales'**
  String get finishedSalesTitle;

  /// No description provided for @creditSalesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Credit sales'**
  String get creditSalesTooltip;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @noFinishedSalesYet.
  ///
  /// In en, this message translates to:
  /// **'No finished sales yet.'**
  String get noFinishedSalesYet;

  /// No description provided for @newSaleTooltip.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get newSaleTooltip;

  /// No description provided for @cancelSaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel sale'**
  String get cancelSaleTitle;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @noCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'No customer'**
  String get noCustomerLabel;

  /// No description provided for @customerNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer #{id}'**
  String customerNumberLabel(int id);

  /// No description provided for @immediateLabel.
  ///
  /// In en, this message translates to:
  /// **'Immediate'**
  String get immediateLabel;

  /// No description provided for @noInstallmentsRegistered.
  ///
  /// In en, this message translates to:
  /// **'No installments registered.'**
  String get noInstallmentsRegistered;

  /// No description provided for @paidInInstallmentsMessage.
  ///
  /// In en, this message translates to:
  /// **'Paid in {count} {count, plural, one{installment} other{installments}}:'**
  String paidInInstallmentsMessage(int count);

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing your experience...'**
  String get splashLoading;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
