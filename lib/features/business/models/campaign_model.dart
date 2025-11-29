import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_model.dart';

class CampaignModel extends FlutterFlowModel {
  FocusNode? campaignTitleFocusNode;
  TextEditingController? campaignTitleTextController;
  String? Function(BuildContext, String?)? campaignTitleTextControllerValidator;

  FocusNode? detailsFocusNode;
  TextEditingController? detailsTextController;
  String? Function(BuildContext, String?)? detailsTextControllerValidator;

  /*
  FocusNode? budgetMinFocusNode;
  TextEditingController? budgetMinTextController;
  String? Function(BuildContext, String?)? budgetMinTextControllerValidator;

  FocusNode? budgetMaxFocusNode;
  TextEditingController? budgetMaxTextController;
  String? Function(BuildContext, String?)? budgetMaxTextControllerValidator;
  */

  DateTime? datePicked1;
  DateTime? datePicked2;

  bool isActive = true;
  bool isVisible = true;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    super.dispose();
    campaignTitleFocusNode?.dispose();
    campaignTitleTextController?.dispose();
    detailsFocusNode?.dispose();
    detailsTextController?.dispose();
    /*
    budgetMinFocusNode?.dispose();
    budgetMinTextController?.dispose();
    budgetMaxFocusNode?.dispose();
    budgetMaxTextController?.dispose();
    */
  }
}