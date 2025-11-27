import 'package:flutter/material.dart';

class BaseScreen extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Widget? drawer;
  final Widget body;
  final bool resizeToAvoidBottomInset;
  final double? horizontalPadding;
  final bool useSafeArea;
  const BaseScreen({
    super.key,
    this.appBar,
    this.drawer,
    this.backgroundColor,
    required this.body,
    this.resizeToAvoidBottomInset = false,
    this.horizontalPadding,
    this.useSafeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      drawer: drawer,
      body: useSafeArea
          ? SafeArea(child: _buildBody(context))
          : _buildBody(context),
    );
  }

  Container _buildBody(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding ?? 15),
      width: MediaQuery.sizeOf(context).width,
      child: body,
    );
  }
}
