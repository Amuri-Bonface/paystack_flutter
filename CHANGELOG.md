# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2025-11-13

### 🚀 Major New Features

#### 🇰🇪 Pesalink Bank Transfer Integration
- **NEW**: Added comprehensive Pesalink support for instant bank-to-bank transfers
- **Transaction Limit**: Up to KES 999,999 per transaction
- **Transfer Time**: Instant bank transfers 24/7
- **Bank Details**: Automatic generation of unique account numbers and references
- **Account Expiry**: 25-minute validity for bank transfers with countdown
- **Error Handling**: Comprehensive error handling for incorrect amounts and expired accounts

#### 🧠 Smart Payment Intelligence
- **Auto-Detection**: Intelligent payment method recommendation based on:
  - Transaction amount
  - Available phone number
  - Transaction speed preferences
  - Fee considerations
- **Amount-Based Routing**:
  - KES 50,000+ → Pesalink (best for high amounts)
  - KES 1,000-50,000 + phone → M-PESA STK Push
  - Any amount → Card (fallback option)

#### 📊 Transaction Limit Management
- **Real-time Validation**: Pre-transaction limit checking for all payment methods
- **Limit Display**: Widget shows transaction limits for each payment method
- **Dynamic Recommendations**: Suggests appropriate methods based on limits
- **Error Prevention**: Prevents failed transactions with invalid amounts

### 🛠️ Technical Enhancements

#### Enhanced Models
- **PaymentResult Extensions**:
  - Added `bankTransferDetails` getter for Pesalink information
  - Enhanced `paymentMethod` getter with better metadata handling
  - Added `formattedAmount` and `formattedFees` utilities
  - Support for transaction reference and metadata
- **KenyaPaymentRequest**: New request model with validation
- **ValidationResult**: Comprehensive request validation system

#### Payment Utils
- **Phone Number Utilities**:
  - `isValidKenyaPhoneNumber()`: Validate all Kenya phone formats
  - `normalizeKenyaPhoneNumber()`: Standardize to +254 format
  - Support for various formats (254..., 07..., +254...)
- **Payment Method Utilities**:
  - `getRecommendedPaymentMethod()`: Smart method recommendation
  - `calculateEstimatedFees()`: Fee calculation for each method
  - `isAmountWithinLimits()`: Transaction limit checking
  - `generatePaymentReference()`: Unique reference generation
- **Pesalink Utilities**:
  - `validatePesalinkDetails()`: Validate bank transfer information
  - `isPesalinkAccountExpired()`: Check transfer expiry
  - `getPesalinkTimeRemaining()`: Get remaining time for transfer

#### Enhanced Widgets
- **KenyaPaymentWidget Improvements**:
  - Added Pesalink payment option with bank transfer UI
  - Enhanced payment method selection with visual indicators
  - Real-time transaction limits display
  - Bank transfer instructions with countdown timer
  - Better error handling and user feedback
  - Support for custom payment method selection
- **Quick Actions**: Pre-configured buttons for common payment amounts

#### Web Support Enhancements
- **FlutterPaystackWebPlugin**: Enhanced web implementation
- **Environment Validation**: HTTPS and Paystack SDK validation
- **Web-Specific Methods**: Optimized for browser-based payments
- **KenyaWebPaymentWidget**: Web-specific payment widget

### 📱 Platform Improvements

#### Android
- **Native Integration**: Full support for all Kenya payment methods
- **Pesalink Support**: Bank transfer handling in native Android
- **Better Error Handling**: Improved error messages and recovery

#### iOS
- **Enhanced iOS Support**: Complete iOS payment handling
- **Kenya Payment Methods**: All payment methods supported on iOS

#### Web
- **Kenya Web Payments**: Optimized web experience for Kenya users
- **Browser Compatibility**: Cross-browser support with fallbacks
- **HTTPS Enforcement**: Security validation for web payments

### 📚 Documentation

#### Complete Kenya Guide
- **Comprehensive Examples**: Examples for each Kenya payment method
- **Migration Guide**: Detailed upgrade path from v1.x and v2.0
- **API Reference**: Complete API documentation with Kenya-specific features
- **Payment Method Comparison**: Detailed comparison of all methods
- **Best Practices**: Security and implementation best practices

#### Enhanced Examples
- **Basic Payment Example**: Complete demonstration of all features
- **Pesalink Example**: Specific bank transfer implementation
- **M-PESA Examples**: Both STK Push and Paybill implementations
- **Airtel Money Example**: Mobile money payment example
- **Widget Examples**: Various widget implementation patterns

### 🔧 Breaking Changes

#### API Changes
- **PaymentResult Structure**: Extended with Kenya-specific metadata
- **Payment Flow**: Intelligent auto-detection replaces manual method selection
- **Method Names**: Added `pesalink` to PaymentMethod enum

#### Migration Required
- **FlutterPaystack.processKenyaPayment()**: New primary payment method
- **Enhanced Models**: Some properties moved to getters
- **Validation**: New validation system for payment requests

### 🐛 Bug Fixes

#### General Fixes
- **Payment Status**: Fixed inconsistent status reporting
- **Error Handling**: Improved error messages and recovery
- **Memory Leaks**: Fixed memory leaks in web implementation
- **Thread Safety**: Improved thread safety in async operations

#### Kenya-Specific Fixes
- **Phone Number**: Fixed phone number parsing edge cases
- **Currency Formatting**: Improved KES currency formatting
- **Transaction Limits**: Fixed limit validation for mobile money
- **Bank Details**: Fixed Pesalink bank transfer details parsing

### 📈 Performance Improvements

#### General
- **Faster Initialization**: Optimized plugin initialization
- **Reduced Memory**: Lower memory footprint across all platforms
- **Better Caching**: Improved caching of payment method configurations

#### Kenya-Specific
- **Mobile Money**: Optimized mobile money transaction processing
- **Bank Transfer**: Improved Pesalink transfer handling
- **Widget Performance**: Enhanced widget rendering performance

### 🔐 Security Enhancements

#### General Security
- **HTTPS Enforcement**: Enforced HTTPS for web payments
- **Key Validation**: Enhanced public key validation
- **Input Sanitization**: Improved input sanitization

#### Kenya-Specific Security
- **Phone Validation**: Enhanced phone number validation
- **Bank Details**: Secure handling of Pesalink bank details
- **Reference Generation**: Cryptographically secure reference generation

### 🧪 Testing

#### Test Coverage
- **Unit Tests**: Added unit tests for all Kenya payment methods
- **Integration Tests**: Integration tests for payment flows
- **Widget Tests**: Widget tests for UI components
- **Platform Tests**: Platform-specific test coverage

#### Test Utilities
- **Mock Responses**: Mock payment responses for testing
- **Test Data**: Kenya-specific test data and scenarios
- **Validation Tests**: Tests for validation functions

## [2.0.0] - 2024-12-01

### 🚀 Major Features
- **Initial Kenya Support**: Added comprehensive Kenya mobile money support
- **M-PESA Integration**: STK Push and Paybill support
- **Airtel Money**: Full Airtel Money integration
- **Enhanced Widgets**: KenyaPaymentWidget and QuickPayButton
- **Modern API**: Callback-based payment handling

### 🔧 Technical
- **SDK Update**: Migrated to flutter_paystack_plus v2.3.0
- **Cross-Platform**: Support for Android, iOS, and Web
- **Country Support**: Primary focus on Kenya payment ecosystem

### 📚 Documentation
- **Kenya Guide**: Comprehensive Kenya payment documentation
- **Examples**: Complete implementation examples
- **Migration Guide**: Upgrade path from v1.x

## [1.0.0] - 2024-01-01

### 🎉 Initial Release
- **Basic Paystack Integration**: Core Paystack functionality
- **Card Payments**: Visa, Mastercard, Amex support
- **Multi-Platform**: Android and iOS support
- **Basic Documentation**: Getting started guide