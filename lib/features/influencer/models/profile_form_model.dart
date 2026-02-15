import 'package:flutter/material.dart';

import '../presentation/profile_form_widget.dart';
import '/flutter_flow/flutter_flow_model.dart';

class InfluencerProfileFormModel
    extends FlutterFlowModel<InfluencerProfileFormWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for influncer_name widget.
  FocusNode? influncerNameFocusNode;
  TextEditingController? influncerNameTextController;
  String? Function(BuildContext, String?)? influncerNameTextControllerValidator;

  // State field(s) for influncer_descreption widget.
  FocusNode? influncerDescreptionFocusNode;
  TextEditingController? influncerDescreptionTextController;
  String? Function(BuildContext, String?)?
  influncerDescreptionTextControllerValidator;

  // State field(s) for phone_number widget.
  FocusNode? phoneNumberFocusNode;
  TextEditingController? phoneNumberTextController;
  String? Function(BuildContext, String?)? phoneNumberTextControllerValidator;

  // State field(s) for email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;

  FocusNode? mediaLicenseFocusNode;
  TextEditingController? mediaLicenseTextController;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    super.dispose();
    influncerNameFocusNode?.dispose();
    influncerNameTextController?.dispose();

    influncerDescreptionFocusNode?.dispose();
    influncerDescreptionTextController?.dispose();

    phoneNumberFocusNode?.dispose();
    phoneNumberTextController?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    mediaLicenseFocusNode?.dispose();
    mediaLicenseTextController?.dispose();
  }
}
