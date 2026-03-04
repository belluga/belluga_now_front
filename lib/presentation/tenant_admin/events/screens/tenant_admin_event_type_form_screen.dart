import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminEventTypeFormScreen extends StatefulWidget {
  const TenantAdminEventTypeFormScreen({
    super.key,
    this.existingType,
  });

  final TenantAdminEventType? existingType;

  @override
  State<TenantAdminEventTypeFormScreen> createState() =>
      _TenantAdminEventTypeFormScreenState();
}

class _TenantAdminEventTypeFormScreenState
    extends State<TenantAdminEventTypeFormScreen> {
  final TenantAdminEventsController _controller =
      GetIt.I.get<TenantAdminEventsController>();

  bool get _isEdit => widget.existingType != null;

  @override
  void initState() {
    super.initState();
    _controller.initEventTypeForm(existingType: widget.existingType);
  }

  Future<void> _save() async {
    final form = _controller.eventTypeFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final name = _controller.eventTypeNameController.text.trim();
    final slug = _controller.eventTypeSlugController.text.trim();
    final description = _controller.eventTypeDescriptionController.text.trim();

    _controller.setEventTypeFormSaving(true);
    _controller.setEventTypeFormError(null);

    try {
      final type = await _controller.saveEventType(
        name: name,
        slug: slug,
        description: description,
        existingType: widget.existingType,
      );

      if (!mounted) {
        return;
      }
      context.router.maybePop(type);
    } catch (error) {
      _controller.setEventTypeFormError(error.toString());
    } finally {
      _controller.setEventTypeFormSaving(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<TenantAdminEventTypeFormState>(
      streamValue: _controller.eventTypeFormStateStreamValue,
      builder: (context, formState) {
        final formError = formState.formError;
        return TenantAdminFormScaffold(
          title: _isEdit ? 'Editar tipo de evento' : 'Criar tipo de evento',
          showHandle: false,
          child: SingleChildScrollView(
            child: Form(
              key: _controller.eventTypeFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (formError != null && formError.isNotEmpty) ...[
                    TenantAdminErrorBanner(
                      rawError: formError,
                      fallbackMessage: 'Falha ao salvar tipo de evento.',
                      onRetry: () => _controller.setEventTypeFormError(null),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TenantAdminFormSectionCard(
                    title: 'Dados do tipo',
                    description:
                        'Use tipos para padronizar o formulário de criação de eventos.',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _controller.eventTypeNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            hintText: 'Ex: Workshop',
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) {
                              return 'Nome é obrigatório.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _controller.eventTypeSlugController,
                          decoration: const InputDecoration(
                            labelText: 'Slug',
                            hintText: 'Ex: workshop',
                          ),
                          inputFormatters: tenantAdminSlugInputFormatters,
                          autocorrect: false,
                          enableSuggestions: false,
                          validator: (value) {
                            return tenantAdminValidateRequiredSlug(
                              value,
                              requiredMessage: 'Slug é obrigatório.',
                              invalidMessage:
                                  'Slug inválido. Use letras minúsculas, números, - ou _.',
                            );
                          },
                          onChanged:
                              _controller.updateEventTypeSlugAutoFlagFromManualInput,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _controller.eventTypeDescriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                          ),
                          minLines: 2,
                          maxLines: 4,
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) {
                              return 'Descrição é obrigatória.';
                            }
                            if (trimmed.length < 10) {
                              return 'Descrição deve ter pelo menos 10 caracteres.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TenantAdminPrimaryFormAction(
                    label: _isEdit ? 'Salvar alterações' : 'Criar tipo',
                    icon: _isEdit ? Icons.save_outlined : Icons.add,
                    isLoading: formState.isSaving,
                    onPressed: formState.isSaving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
