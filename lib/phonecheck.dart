import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneCheck extends StatefulWidget {
  const PhoneCheck({super.key});

  @override
  State<PhoneCheck> createState() => _PhoneCheckState();
}

class _PhoneCheckState extends State<PhoneCheck> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  String? verificationId;
  String? phoneNumber;
  int? resendToken;
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      verificationId = args['verificationId'];
      phoneNumber = args['phoneNumber'];
      resendToken = args['resendToken'];
    }

    if (phoneNumber == null || verificationId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid verification data.')),
        );
        Navigator.pop(context, 'back');
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String get otpCode => _controllers.map((c) => c.text).join();

  Future<void> verifyOTP() async {
    if (otpCode.length != 6 || otpCode.contains(RegExp(r'[^0-9]'))) {
      showSnackBar("Enter a valid 6-digit OTP.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otpCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        showSnackBar("Phone number verified!");
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        showSnackBar("Verification failed. User not found.");
      }
    } on FirebaseAuthException catch (e) {
      showSnackBar("Firebase Error: ${e.message}");
    } catch (e) {
      showSnackBar("Unexpected error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> resendOTP() async {
    if (phoneNumber == null) return;

    setState(() => isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber!,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        Navigator.pushReplacementNamed(context, '/home');
      },
      verificationFailed: (error) {
        showSnackBar("Verification failed: ${error.message}");
      },
      codeSent: (newVerificationId, newResendToken) {
        setState(() {
          verificationId = newVerificationId;
          resendToken = newResendToken;
        });
        showSnackBar("OTP resent successfully.");
      },
      codeAutoRetrievalTimeout: (id) {
        verificationId = id;
      },
    );

    setState(() => isLoading = false);
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 40,
      child: TextField(
        controller: _controllers[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        decoration: const InputDecoration(
          counterText: "",
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          if (value.length == 1 && index < 5) {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, 'back');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Verify OTP')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "Enter the OTP sent to $phoneNumber",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: _buildOtpField(i),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: verifyOTP,
                      child: const Text("Verify OTP"),
                    ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: isLoading ? null : resendOTP,
                child: const Text("Resend OTP"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
