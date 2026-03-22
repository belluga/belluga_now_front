import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'rules/controller_buildcontext_dependency_forbidden_rule.dart';
import 'rules/controller_direct_navigation_forbidden_rule.dart';
import 'rules/domain_dto_dependency_forbidden_rule.dart';
import 'rules/domain_json_factory_forbidden_rule.dart';
import 'rules/domain_primitive_field_forbidden_rule.dart';
import 'rules/global_ui_controller_naming_forbidden_rule.dart';
import 'rules/module_direct_getit_registration_forbidden_rule.dart';
import 'rules/module_scoped_controller_dispose_forbidden_rule.dart';
import 'rules/multi_public_class_file_warning_rule.dart';
import 'rules/multi_widget_file_warning_rule.dart';
import 'rules/repository_inline_dto_to_domain_mapper_forbidden_rule.dart';
import 'rules/repository_json_parsing_forbidden_rule.dart';
import 'rules/repository_raw_payload_map_forbidden_rule.dart';
import 'rules/repository_raw_transport_typing_forbidden_rule.dart';
import 'rules/route_page_must_live_in_routes_folder_rule.dart';
import 'rules/route_path_param_requires_resolver_route_rule.dart';
import 'rules/screen_controller_resolution_pattern_required_rule.dart';
import 'rules/service_json_parsing_forbidden_rule.dart';
import 'rules/tenant_canonical_domain_required_rule.dart';
import 'rules/ui_route_param_hydration_forbidden_rule.dart';
import 'rules/ui_build_side_effects_forbidden_rule.dart';
import 'rules/ui_cross_feature_controller_resolution_forbidden_rule.dart';
import 'rules/ui_direct_repository_service_resolution_forbidden_rule.dart';
import 'rules/ui_dto_import_forbidden_rule.dart';
import 'rules/ui_future_stream_builder_forbidden_rule.dart';
import 'rules/ui_getit_non_controller_forbidden_rule.dart';
import 'rules/ui_navigation_after_await_forbidden_rule.dart';
import 'rules/ui_navigator_usage_forbidden_rule.dart';
import 'rules/ui_controller_ownership_forbidden_rule.dart';
import 'rules/ui_streamvalue_ownership_forbidden_rule.dart';

class BellugaCustomLintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        UiGetItNonControllerForbiddenRule(),
        UiDirectRepositoryServiceResolutionForbiddenRule(),
        UiCrossFeatureControllerResolutionForbiddenRule(),
        ModuleScopedControllerDisposeForbiddenRule(),
        UiStreamValueOwnershipForbiddenRule(),
        UiDtoImportForbiddenRule(),
        DomainDtoDependencyForbiddenRule(),
        DomainJsonFactoryForbiddenRule(),
        DomainPrimitiveFieldForbiddenRule(),
        UiFutureStreamBuilderForbiddenRule(),
        UiNavigatorUsageForbiddenRule(),
        UiNavigationAfterAwaitForbiddenRule(),
        UiBuildSideEffectsForbiddenRule(),
        UiControllerOwnershipForbiddenRule(),
        RepositoryJsonParsingForbiddenRule(),
        RepositoryRawPayloadMapForbiddenRule(),
        RepositoryRawTransportTypingForbiddenRule(),
        ServiceJsonParsingForbiddenRule(),
        RepositoryInlineDtoToDomainMapperForbiddenRule(),
        ModuleDirectGetItRegistrationForbiddenRule(),
        GlobalUiControllerNamingForbiddenRule(),
        ControllerBuildContextDependencyForbiddenRule(),
        ControllerDirectNavigationForbiddenRule(),
        RoutePageMustLiveInRoutesFolderRule(),
        RoutePathParamRequiresResolverRouteRule(),
        ScreenControllerResolutionPatternRequiredRule(),
        UiRouteParamHydrationForbiddenRule(),
        MultiPublicClassFileWarningRule(),
        MultiWidgetFileWarningRule(),
        TenantCanonicalDomainRequiredRule(),
      ];
}
