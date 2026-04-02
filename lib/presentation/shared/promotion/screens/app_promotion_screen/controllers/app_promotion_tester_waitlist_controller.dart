import 'package:belluga_now/application/contracts/promotion/promotion_lead_capture_field_payload.dart';
import 'package:belluga_now/application/contracts/promotion/promotion_lead_capture_request.dart';
import 'package:belluga_now/application/contracts/promotion/promotion_lead_capture_service_contract.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/promotion/promotion_lead_mobile_platform.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class AppPromotionTesterWaitlistController implements Disposable {
  AppPromotionTesterWaitlistController({
    AppDataRepositoryContract? appDataRepository,
    PromotionLeadCaptureServiceContract? leadCaptureService,
  })  : _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _leadCaptureService = leadCaptureService ??
            GetIt.I.get<PromotionLeadCaptureServiceContract>();

  final AppDataRepositoryContract _appDataRepository;
  final PromotionLeadCaptureServiceContract _leadCaptureService;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController expectationsController = TextEditingController();

  final StreamValue<String?> nameErrorStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<String?> emailErrorStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<String?> whatsappErrorStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<String?> expectationsErrorStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<String?> platformErrorStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<PromotionLeadMobilePlatform?> selectedPlatformStreamValue =
      StreamValue<PromotionLeadMobilePlatform?>(defaultValue: null);
  final StreamValue<bool> isSubmittingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> submissionSucceededStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> submissionErrorMessageStreamValue =
      StreamValue<String?>(defaultValue: null);

  String get appDisplayName {
    final normalized = _appDataRepository.appData.nameValue.value.trim();
    return normalized.isEmpty ? 'Belluga' : normalized;
  }

  void reset() {
    nameController.clear();
    emailController.clear();
    whatsappController.clear();
    expectationsController.clear();
    nameErrorStreamValue.addValue(null);
    emailErrorStreamValue.addValue(null);
    whatsappErrorStreamValue.addValue(null);
    expectationsErrorStreamValue.addValue(null);
    platformErrorStreamValue.addValue(null);
    selectedPlatformStreamValue.addValue(null);
    isSubmittingStreamValue.addValue(false);
    submissionSucceededStreamValue.addValue(false);
    submissionErrorMessageStreamValue.addValue(null);
  }

  void onNameChanged(String _) {
    nameErrorStreamValue.addValue(null);
    submissionErrorMessageStreamValue.addValue(null);
  }

  void onEmailChanged(String _) {
    emailErrorStreamValue.addValue(null);
    submissionErrorMessageStreamValue.addValue(null);
  }

  void onWhatsappChanged(String _) {
    whatsappErrorStreamValue.addValue(null);
    submissionErrorMessageStreamValue.addValue(null);
  }

  void onExpectationsChanged(String _) {
    expectationsErrorStreamValue.addValue(null);
    submissionErrorMessageStreamValue.addValue(null);
  }

  void selectPlatform(PromotionLeadMobilePlatform platform) {
    selectedPlatformStreamValue.addValue(platform);
    platformErrorStreamValue.addValue(null);
    submissionErrorMessageStreamValue.addValue(null);
  }

  Future<void> submit() async {
    if (isSubmittingStreamValue.value) {
      return;
    }

    submissionErrorMessageStreamValue.addValue(null);
    submissionSucceededStreamValue.addValue(false);

    if (!_validate()) {
      return;
    }

    isSubmittingStreamValue.addValue(true);
    try {
      await _leadCaptureService.submitTesterWaitlistLead(_buildRequest());
      submissionSucceededStreamValue.addValue(true);
    } catch (error) {
      submissionErrorMessageStreamValue.addValue(
        'Tivemos um problema para registrar seu contato. Detalhes: ${_formatSubmissionError(error)}',
      );
    } finally {
      isSubmittingStreamValue.addValue(false);
    }
  }

  bool _validate() {
    var isValid = true;

    final normalizedName = nameController.text.trim();
    if (normalizedName.isEmpty) {
      nameErrorStreamValue.addValue('Insira seu nome.');
      isValid = false;
    } else {
      nameErrorStreamValue.addValue(null);
    }

    final normalizedEmail = emailController.text.trim();
    if (!_isValidEmail(normalizedEmail)) {
      emailErrorStreamValue.addValue('Insira um e-mail válido.');
      isValid = false;
    } else {
      emailErrorStreamValue.addValue(null);
    }

    final normalizedPhone = _normalizedWhatsappDigits(whatsappController.text);
    if (normalizedPhone.length < 10 || normalizedPhone.length > 11) {
      whatsappErrorStreamValue.addValue('Insira um WhatsApp válido.');
      isValid = false;
    } else {
      whatsappErrorStreamValue.addValue(null);
    }

    final normalizedExpectations = expectationsController.text.trim();
    if (normalizedExpectations.isEmpty) {
      expectationsErrorStreamValue.addValue(
        'Conte para nós o que você espera encontrar.',
      );
      isValid = false;
    } else {
      expectationsErrorStreamValue.addValue(null);
    }

    if (selectedPlatformStreamValue.value == null) {
      platformErrorStreamValue.addValue('Selecione uma opção.');
      isValid = false;
    } else {
      platformErrorStreamValue.addValue(null);
    }

    return isValid;
  }

  PromotionLeadCaptureRequest _buildRequest() {
    final appNameValue = EnvironmentNameValue()..parse(appDisplayName);
    return PromotionLeadCaptureRequest(
      appNameValue: appNameValue,
      submittedFields: <PromotionLeadCaptureFieldPayload>[
        PromotionLeadCaptureFieldPayload(
          label: 'Seu Nome',
          value: nameController.text.trim(),
        ),
        PromotionLeadCaptureFieldPayload(
          label: 'E-mail',
          value: emailController.text.trim(),
        ),
        PromotionLeadCaptureFieldPayload(
          label: 'WhatsApp',
          value: _normalizedWhatsappDigits(whatsappController.text),
        ),
        PromotionLeadCaptureFieldPayload(
          label: 'Qual o seu sistema operacional?',
          value: selectedPlatformStreamValue.value!.label,
        ),
        PromotionLeadCaptureFieldPayload(
          label: 'O que não pode faltar para atender às suas expectativas?',
          value: expectationsController.text.trim(),
        ),
      ],
    );
  }

  String _normalizedWhatsappDigits(String raw) => raw.replaceAll(
        RegExp(r'\D'),
        '',
      );

  bool _isValidEmail(String email) {
    if (email.isEmpty) {
      return false;
    }
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  String _formatSubmissionError(Object error) {
    var normalized = error.toString().trim();
    if (normalized.isEmpty) {
      return 'erro desconhecido';
    }
    const stateErrorPrefix = 'Bad state: ';
    if (normalized.startsWith(stateErrorPrefix)) {
      normalized = normalized.substring(stateErrorPrefix.length).trim();
    }
    if (normalized.contains('XMLHttpRequest') ||
        normalized.contains('connection error')) {
      return 'falha de conexão com o serviço externo';
    }
    return normalized;
  }

  @override
  void onDispose() {
    nameController.dispose();
    emailController.dispose();
    whatsappController.dispose();
    expectationsController.dispose();
    nameErrorStreamValue.dispose();
    emailErrorStreamValue.dispose();
    whatsappErrorStreamValue.dispose();
    expectationsErrorStreamValue.dispose();
    platformErrorStreamValue.dispose();
    selectedPlatformStreamValue.dispose();
    isSubmittingStreamValue.dispose();
    submissionSucceededStreamValue.dispose();
    submissionErrorMessageStreamValue.dispose();
  }
}
