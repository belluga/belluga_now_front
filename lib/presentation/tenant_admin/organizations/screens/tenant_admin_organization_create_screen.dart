import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/organizations/controllers/tenant_admin_organizations_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminOrganizationCreateScreen extends StatefulWidget {
  const TenantAdminOrganizationCreateScreen({super.key});

  @override
  State<TenantAdminOrganizationCreateScreen> createState() =>
      _TenantAdminOrganizationCreateScreenState();
}

class _TenantAdminOrganizationCreateScreenState
    extends State<TenantAdminOrganizationCreateScreen> {
  final TenantAdminOrganizationsController _controller =
      GetIt.I.get<TenantAdminOrganizationsController>();

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.createSuccessMessageStreamValue,
      builder: (context, successMessage) {
        _handleCreateSuccessMessage(successMessage);
        return StreamValueBuilder<String?>(
          streamValue: _controller.createErrorMessageStreamValue,
          builder: (context, errorMessage) {
            _handleCreateErrorMessage(errorMessage);
            return TenantAdminFormScaffold(
              title: 'Criar Organizacao',
              child: SingleChildScrollView(
                child: Form(
                  key: _controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TenantAdminFormSectionCard(
                        title: 'Dados da organizacao',
                        description:
                            'Informe os dados basicos para cadastrar uma nova organizacao no tenant.',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _controller.nameController,
                              decoration:
                                  const InputDecoration(labelText: 'Nome'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nome e obrigatorio.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _controller.descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Descricao (opcional)',
                              ),
                              minLines: 2,
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TenantAdminPrimaryFormAction(
                        label: 'Salvar organizacao',
                        icon: Icons.save_outlined,
                        onPressed: () {
                          final form = _controller.formKey.currentState;
                          if (form == null || !form.validate()) {
                            return;
                          }
                          _controller.submitCreateOrganization(
                            name: _controller.nameController.text.trim(),
                            description:
                                _controller.descriptionController.text.trim(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleCreateSuccessMessage(String? message) {
    if (message == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.clearCreateSuccessMessage();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      context.router.maybePop();
    });
  }

  void _handleCreateErrorMessage(String? message) {
    if (message == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.clearCreateErrorMessage();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }
}
