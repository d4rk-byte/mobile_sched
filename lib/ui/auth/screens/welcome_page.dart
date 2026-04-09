import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../auth_constants.dart';
import '../widgets/widgets.dart';
import 'signin_page.dart';
import 'register_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAuthBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: const Image(
                          image: AssetImage(
                            'assets/images/team_illustration.png',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Faculty Scheduling\nSystem",
                      style: kAuthHeadline,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: const Text(
                        "Manage your classes, schedules, and collaborate with your team. Including mobile and desktop access.",
                        style: kAuthBodyText,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: kAuthCardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kAuthCardBorderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AuthTextButton(
                        bgColor: kAuthPrimaryButtonColor,
                        buttonName: 'Register',
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        textColor: kAuthPrimaryButtonTextColor,
                      ),
                    ),
                    Expanded(
                      child: AuthTextButton(
                        bgColor: Colors.transparent,
                        buttonName: 'Sign In',
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => const SignInPage(),
                            ),
                          );
                        },
                        textColor: kAuthLinkColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
