import 'package:elan_flutterproject/flutter_flow/flutter_flow_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../presentation/profile_form_widget.dart';

class BusinessProfileFormModel
    extends FlutterFlowModel<BusinessProfileFormWidget> {
  ///  State fields for stateful widgets in this page.
  // State field(s) for business_name widget.
  FocusNode? businessNameFocusNode;
  TextEditingController? businessNameTextController;
  String? Function(BuildContext, String?)? businessNameTextControllerValidator;
  // State field(s) for business_descreption widget.
  FocusNode? businessDescreptionFocusNode;
  GlobalKey<FormState> businessDescreptionFormKey = GlobalKey<FormState>();
  TextEditingController? businessDescreptionTextController;
  String? Function(BuildContext, String?)?
  businessDescreptionTextControllerValidator;

  // State field(s) for phone_number widget.
  FocusNode? phoneNumberFocusNode;
  TextEditingController? phoneNumberTextController;
  String? Function(BuildContext, String?)? phoneNumberTextControllerValidator;

  // State field(s) for email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;

  // State field(s) for profile image.
  XFile? profileImage;
  bool isImageFromFile = false;

  String? existingImageUrl;

  @override
  void initState(BuildContext context) {
    businessDescreptionTextController ??= TextEditingController();
    businessDescreptionFocusNode ??= FocusNode();
    phoneNumberTextController ??= TextEditingController();
    phoneNumberFocusNode ??= FocusNode();
    emailTextController ??= TextEditingController();
    emailFocusNode ??= FocusNode();

    // Require at least one of phone or email. If one has value, the other is considered valid.
    phoneNumberTextControllerValidator ??= (context, value) {
      final phone = phoneNumberTextController?.text.trim() ?? '';
      final email = emailTextController?.text.trim() ?? '';
      if (phone.isEmpty && email.isEmpty) {
        return 'يرجئ إدخال رقم الجوال أو الايميل';
      }
      return null;
    };

    emailTextControllerValidator ??= (context, value) {
      final phone = phoneNumberTextController?.text.trim() ?? '';
      final email = emailTextController?.text.trim() ?? '';
      if (phone.isEmpty && email.isEmpty) {
        return 'يرجئ إدخال الايميل أو رقم الجوال';
      }
      return null;
    };
  }

  @override
  void dispose() {
    businessDescreptionFocusNode?.dispose();
    businessDescreptionTextController?.dispose();
    phoneNumberFocusNode?.dispose();
    phoneNumberTextController?.dispose();
    emailFocusNode?.dispose();
    emailTextController?.dispose();
    super.dispose();
  }
}
