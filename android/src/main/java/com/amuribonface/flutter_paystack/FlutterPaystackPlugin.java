package com.amuribonface.flutter_paystack;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

/**
 * FlutterPaystackPlugin
 *
 * This plugin integrates Paystack Payment Gateway with Flutter for Kenyan mobile payments.
 * Supports M-PESA STK Push, M-PESA Paybill, Airtel Money, Pesalink bank transfers, and card payments.
 */
public class FlutterPaystackPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private static final String TAG = "FlutterPaystackPlugin";
    private static final String CHANNEL_NAME = "flutter_paystack";

    private MethodChannel channel;
    private Context applicationContext;
    private Activity currentActivity;
    private static final int PAYMENT_REQUEST_CODE = 1001;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_NAME);
        channel.setMethodCallHandler(this);
        applicationContext = flutterPluginBinding.getApplicationContext();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        currentActivity = binding.getActivity();
        binding.addActivityResultListener(this);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        currentActivity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        currentActivity = binding.getActivity();
        binding.addActivityResultListener(this);
    }

    @Override
    public void onDetachedFromActivity() {
        currentActivity = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        try {
            switch (call.method) {
                case "initialize":
                    initialize(call, result);
                    break;
                case "processPayment":
                    processPayment(call, result);
                    break;
                case "verifyTransaction":
                    verifyTransaction(call, result);
                    break;
                case "getAccessCode":
                    getAccessCode(call, result);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error in onMethodCall: " + call.method, e);
            result.error("PLUGIN_ERROR", "Error processing method call: " + e.getMessage(), null);
        }
    }

    private void initialize(MethodCall call, Result result) {
        try {
            String publicKey = call.argument("publicKey");
            String environment = call.argument("environment");
            
            if (publicKey == null || publicKey.isEmpty()) {
                result.error("INVALID_PUBLIC_KEY", "Public key cannot be null or empty", null);
                return;
            }
            
            // Initialize Paystack SDK
            Log.d(TAG, "Initializing Paystack with public key: " + publicKey);
            
            // Store configuration for later use
            com.paystack.imp.models.PaystackConfig.initialize(publicKey, environment != null ? environment : "sandbox");
            
            result.success("Paystack initialized successfully");
        } catch (Exception e) {
            Log.e(TAG, "Error initializing Paystack", e);
            result.error("INITIALIZATION_ERROR", "Failed to initialize Paystack: " + e.getMessage(), null);
        }
    }

    private void processPayment(MethodCall call, Result result) {
        try {
            if (currentActivity == null) {
                result.error("NO_ACTIVITY", "No current activity available", null);
                return;
            }
            
            // Extract payment parameters
            String email = call.argument("email");
            int amount = call.argument("amount");
            String currency = call.argument("currency");
            String reference = call.argument("reference");
            String paymentMethod = call.argument("paymentMethod");
            String phone = call.argument("phone");
            String bankCode = call.argument("bankCode");
            String bankAccount = call.argument("bankAccount");
            
            if (email == null || email.isEmpty()) {
                result.error("INVALID_EMAIL", "Email cannot be null or empty", null);
                return;
            }
            
            if (amount <= 0) {
                result.error("INVALID_AMOUNT", "Amount must be greater than 0", null);
                return;
            }
            
            Log.d(TAG, "Processing payment: " + amount + " " + currency + " for " + email);
            
            // Create Paystack transaction builder
            com.paystack.imp.models.Transaction transaction = com.paystack.imp.models.Payment.builder()
                .email(email)
                .amount(amount)
                .reference(reference)
                .currency(currency)
                .build()
                .toTransaction();
            
            // Handle different payment methods
            if ("mobile_money".equals(paymentMethod)) {
                transaction.setMobileMoney((com.paystack.imp.models.MobileMoney) call.argument("mobileMoney"));
            } else if ("bank_transfer".equals(paymentMethod)) {
                transaction.setBankTransfer((com.paystack.imp.models.BankTransfer) call.argument("bankTransfer"));
            } else if ("card".equals(paymentMethod)) {
                // Card payments use the standard transaction flow
            }
            
            // Initialize Paystack transaction
            transaction.initialize(currentActivity, new com.paystack.imp.interfaces.PaymentCallback() {
                @Override
                public void onSuccess(com.paystack.imp.models.Transaction transaction) {
                    Log.d(TAG, "Payment successful: " + transaction.getReference());
                    result.success(createSuccessResponse(transaction));
                }
                
                @Override
                public void onFailure(com.paystack.imp.models.Transaction transaction, int errorCode, String errorMessage) {
                    Log.e(TAG, "Payment failed: " + errorMessage);
                    result.error("PAYMENT_FAILED", errorMessage, createErrorResponse(errorCode, errorMessage));
                }
                
                @Override
                public void onRequiredFieldsEmpty(com.paystack.imp.models.Transaction transaction) {
                    Log.e(TAG, "Required fields are empty");
                    result.error("REQUIRED_FIELDS_EMPTY", "Required fields are empty", null);
                }
            });
            
        } catch (Exception e) {
            Log.e(TAG, "Error processing payment", e);
            result.error("PAYMENT_PROCESSING_ERROR", "Failed to process payment: " + e.getMessage(), null);
        }
    }

    private void verifyTransaction(MethodCall call, Result result) {
        try {
            String reference = call.argument("reference");
            
            if (reference == null || reference.isEmpty()) {
                result.error("INVALID_REFERENCE", "Reference cannot be null or empty", null);
                return;
            }
            
            Log.d(TAG, "Verifying transaction: " + reference);
            
            // Create verification request
            com.paystack.imp.models.CardVerificationRequest request = 
                new com.paystack.imp.models.CardVerificationRequest(reference, applicationContext);
            
            request.verify(new com.paystack.imp.interfaces.CardVerificationCallback() {
                @Override
                public void onVerificationSuccess(com.paystack.imp.models.CardVerificationResponse response) {
                    Log.d(TAG, "Transaction verification successful");
                    result.success(createVerificationResponse(response));
                }
                
                @Override
                public void onVerificationFailure(com.paystack.imp.models.CardVerificationResponse response) {
                    Log.e(TAG, "Transaction verification failed");
                    result.error("VERIFICATION_FAILED", "Transaction verification failed", null);
                }
                
                @Override
                public void onVerificationRequest() {
                    // No action needed for now
                }
            });
            
        } catch (Exception e) {
            Log.e(TAG, "Error verifying transaction", e);
            result.error("VERIFICATION_ERROR", "Failed to verify transaction: " + e.getMessage(), null);
        }
    }

    private void getAccessCode(MethodCall call, Result result) {
        try {
            // Generate a unique access code for the transaction
            String accessCode = "pk_" + System.currentTimeMillis();
            result.success(accessCode);
        } catch (Exception e) {
            Log.e(TAG, "Error generating access code", e);
            result.error("ACCESS_CODE_ERROR", "Failed to generate access code: " + e.getMessage(), null);
        }
    }

    private com.paystack.imp.models.Transaction loadTransactionFromCall(MethodCall call) {
        com.paystack.imp.models.Transaction transaction = new com.paystack.imp.models.Transaction();
        
        if (call.hasArgument("email")) {
            transaction.setEmail((String) call.argument("email"));
        }
        if (call.hasArgument("amount")) {
            transaction.setAmount((Integer) call.argument("amount"));
        }
        if (call.hasArgument("reference")) {
            transaction.setReference((String) call.argument("reference"));
        }
        if (call.hasArgument("currency")) {
            transaction.setCurrency((String) call.argument("currency"));
        }
        
        return transaction;
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {
        Log.d(TAG, "Activity result received: " + requestCode + ", resultCode: " + resultCode);
        
        if (requestCode == PAYMENT_REQUEST_CODE) {
            // Handle Paystack activity result
            if (resultCode == Activity.RESULT_OK) {
                Log.d(TAG, "Payment completed successfully");
                // The transaction callback will handle the success
            } else {
                Log.d(TAG, "Payment was cancelled or failed");
                // The transaction callback will handle the failure
            }
            return true;
        }
        
        return false;
    }

    // Helper methods to create response objects
    private java.util.Map<String, Object> createSuccessResponse(com.paystack.imp.models.Transaction transaction) {
        java.util.Map<String, Object> response = new java.util.HashMap<>();
        response.put("status", "success");
        response.put("reference", transaction.getReference());
        response.put("amount", transaction.getAmount());
        response.put("currency", transaction.getCurrency());
        response.put("message", "Payment successful");
        return response;
    }

    private java.util.Map<String, Object> createErrorResponse(int errorCode, String errorMessage) {
        java.util.Map<String, Object> response = new java.util.HashMap<>();
        response.put("status", "error");
        response.put("errorCode", errorCode);
        response.put("errorMessage", errorMessage);
        return response;
    }

    private java.util.Map<String, Object> createVerificationResponse(com.paystack.imp.models.CardVerificationResponse response) {
        java.util.Map<String, Object> result = new java.util.HashMap<>();
        result.put("verified", response.getStatus().equals("success"));
        result.put("data", response.getData());
        return result;
    }
}