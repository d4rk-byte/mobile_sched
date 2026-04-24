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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final heroWidth = screenWidth * 0.8;

    return Scaffold(
      backgroundColor: kAuthBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kAuthPageHorizontalPadding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(height: kAuthSectionSpacing),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AuthStaggeredEntrance(
                            delay: Duration.zero,
                            child: Center(
                              child: SizedBox(
                                width: heroWidth,
                                child: const Image(
                                  image: AssetImage(
                                    'assets/images/team_illustration.png',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: kAuthSectionSpacing),
                          const AuthStaggeredEntrance(
                            delay: Duration(milliseconds: 40),
                            child: Text(
                              "Faculty Scheduling\nSystem",
                              style: kAuthHeadline,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: kAuthElementSpacing),
                          AuthStaggeredEntrance(
                            delay: const Duration(milliseconds: 80),
                            child: SizedBox(
                              width: heroWidth,
                              child: const Text(
                                "Manage your classes, schedules, and collaborate with your team. Including mobile and desktop access.",
                                style: kAuthBodyText,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          AuthStaggeredEntrance(
                            delay: const Duration(milliseconds: 120),
                            child: Container(
                              height: kAuthControlHeight,
                              decoration: BoxDecoration(
                                color: kAuthCardColor,
                                borderRadius:
                                    BorderRadius.circular(kAuthFieldRadius),
                                border: Border.all(color: kAuthCardBorderColor),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Semantics(
                                      button: true,
                                      label: 'Register',
                                      hint: 'Navigates to registration',
                                      child: AuthTextButton(
                                        bgColor: kAuthPrimaryButtonColor,
                                        buttonName: 'Register',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            CupertinoPageRoute(
                                              builder: (context) =>
                                                  const RegisterPage(),
                                            ),
                                          );
                                        },
                                        textColor: kAuthPrimaryButtonTextColor,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Semantics(
                                      button: true,
                                      label: 'Sign In',
                                      hint: 'Navigates to sign in',
                                      child: AuthTextButton(
                                        bgColor: Colors.transparent,
                                        buttonName: 'Sign In',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            CupertinoPageRoute(
                                              builder: (context) =>
                                                  const SignInPage(),
                                            ),
                                          );
                                        },
                                        textColor: kAuthLinkColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: kAuthPageBottomSpacing),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
