import 'package:flutter/material.dart';

import '../presentation/experience_edit_widget.dart';
import '/flutter_flow/flutter_flow_model.dart';

class InfluncerEditExperienceModel
    extends FlutterFlowModel<InfluncerEditExperienceWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for campaign_title widget.
  FocusNode? campaignTitleFocusNode;
  TextEditingController? campaignTitleTextController;
  String? Function(BuildContext, String?)? campaignTitleTextControllerValidator;
  DateTime? datePicked1;
  DateTime? datePicked2;

  // State field(s) for details widget.
  FocusNode? detailsFocusNode;
  TextEditingController? detailsTextController;
  String? Function(BuildContext, String?)? detailsTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    super.dispose();
    campaignTitleFocusNode?.dispose();
    campaignTitleTextController?.dispose();

    detailsFocusNode?.dispose();
    detailsTextController?.dispose();
  }
}
