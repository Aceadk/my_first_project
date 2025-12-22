class DsBreakpoints {
  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  static bool isMobile(double width) => width < mobileMax;
  static bool isTablet(double width) => width >= mobileMax && width < tabletMax;
  static bool isDesktop(double width) => width >= tabletMax;
}
