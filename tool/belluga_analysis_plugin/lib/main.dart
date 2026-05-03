import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:belluga_analysis_plugin/src/rules/controller_buildcontext_dependency_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/controller_controller_dependency_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/controller_delegated_streamvalue_snapshot_field_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/controller_direct_navigation_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/controller_delegated_streamvalue_dispose_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/controller_delegated_streamvalue_write_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/controller_owned_streamvalue_dispose_required_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/controller_repository_async_model_fetch_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/controller_repository_pagination_arguments_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/controller_streamvalue_parameter_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/controller_streamvalue_model_ownership_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/domain_dto_dependency_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/domain_json_factory_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/domain_paged_result_type_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/domain_primitive_field_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/dto_mapper_pass_through_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/flutter_sentry_unreported_debug_print_catch_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/global_ui_controller_naming_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/integration_anonymous_auth_identified_login_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/location_origin_canonical_resolution_required_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/location_origin_canonical_stream_subscription_required_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/module_direct_getit_registration_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/module_scoped_controller_dispose_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/multi_public_class_file_warning_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/multi_widget_file_warning_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/repository_inline_dto_to_domain_mapper_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/repository_contract_pagination_controls_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/repository_json_parsing_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/repository_model_stream_lifecycle_methods_required_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/repository_model_streamvalue_nullable_required_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/repository_registration_lifecycle_enforced_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/repository_registration_scope_enforced_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/repository_service_catch_return_fallback_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/repository_raw_payload_map_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/repository_raw_transport_typing_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/route_page_must_live_in_routes_folder_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/route_path_param_requires_resolver_route_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/route_required_non_url_args_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/screen_controller_resolution_pattern_required_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/screen_descendant_widget_controller_resolution_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/service_json_parsing_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/tenant_canonical_domain_required_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/timezone_service_direct_datetime_conversion_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/ui_route_param_hydration_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/ui_build_side_effects_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/ui_cross_feature_controller_resolution_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/ui_direct_repository_service_resolution_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/ui_dto_import_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/ui_future_stream_builder_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/ui_getit_non_controller_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/ui_navigation_after_await_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/ui_navigator_usage_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/ui_controller_ownership_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/ui_streamvalue_ownership_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/ui_streamvalue_builder_null_check_forbidden_rule.dart';
import 'package:belluga_analysis_plugin/src/rules/widget_controller_singleton_registration_forbidden_rule.dart';

final plugin = BellugaAnalysisPlugin();

class BellugaAnalysisPlugin extends Plugin {
  @override
  String get name => 'Belluga Analysis Plugin';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(UiGetItNonControllerForbiddenRule());
    registry.registerWarningRule(
      UiDirectRepositoryServiceResolutionForbiddenRule(),
    );
    registry.registerWarningRule(
      UiCrossFeatureControllerResolutionForbiddenRule(),
    );
    registry.registerWarningRule(ModuleScopedControllerDisposeForbiddenRule());
    registry.registerWarningRule(UiStreamValueOwnershipForbiddenRule());
    registry.registerWarningRule(UiDtoImportForbiddenRule());
    registry.registerWarningRule(DomainDtoDependencyForbiddenRule());
    registry.registerWarningRule(DomainJsonFactoryForbiddenRule());
    registry.registerWarningRule(DomainPagedResultTypeForbiddenRule());
    registry.registerWarningRule(DomainPrimitiveFieldForbiddenRule());
    registry.registerWarningRule(DtoMapperPassThroughForbiddenRule());
    registry.registerWarningRule(UiFutureStreamBuilderForbiddenRule());
    registry.registerWarningRule(UiNavigatorUsageForbiddenRule());
    registry.registerWarningRule(UiNavigationAfterAwaitForbiddenRule());
    registry.registerWarningRule(UiBuildSideEffectsForbiddenRule());
    registry.registerWarningRule(UiControllerOwnershipForbiddenRule());
    registry.registerWarningRule(UiStreamValueBuilderNullCheckForbiddenRule());
    registry.registerWarningRule(RepositoryJsonParsingForbiddenRule());
    registry.registerWarningRule(
      RepositoryModelStreamLifecycleMethodsRequiredRule(),
    );
    registry.registerWarningRule(
      RepositoryModelStreamValueNullableRequiredRule(),
    );
    registry.registerWarningRule(RepositoryRegistrationScopeEnforcedRule());
    registry.registerWarningRule(RepositoryRegistrationLifecycleEnforcedRule());
    registry.registerWarningRule(
      RepositoryContractPaginationControlsForbiddenRule(),
    );
    registry.registerWarningRule(
      RepositoryServiceCatchReturnFallbackForbiddenRule(),
    );
    registry.registerWarningRule(RepositoryRawPayloadMapForbiddenRule());
    registry.registerWarningRule(RepositoryRawTransportTypingForbiddenRule());
    registry.registerWarningRule(ServiceJsonParsingForbiddenRule());
    registry.registerWarningRule(
      RepositoryInlineDtoToDomainMapperForbiddenRule(),
    );
    registry.registerWarningRule(ModuleDirectGetItRegistrationForbiddenRule());
    registry.registerWarningRule(GlobalUiControllerNamingForbiddenRule());
    registry.registerWarningRule(
      ControllerBuildContextDependencyForbiddenRule(),
    );
    registry.registerWarningRule(ControllerControllerDependencyForbiddenRule());
    registry.registerWarningRule(
      ControllerDelegatedStreamValueSnapshotFieldForbiddenRule(),
    );
    registry.registerWarningRule(ControllerDirectNavigationForbiddenRule());
    registry.registerWarningRule(
      ControllerRepositoryAsyncModelFetchForbiddenRule(),
    );
    registry.registerWarningRule(
      ControllerRepositoryPaginationArgumentsForbiddenRule(),
    );
    registry.registerWarningRule(
      ControllerDelegatedStreamValueDisposeForbiddenRule(),
    );
    registry.registerWarningRule(
      ControllerDelegatedStreamValueWriteForbiddenRule(),
    );
    registry.registerWarningRule(ControllerStreamValueParameterForbiddenRule());
    registry.registerWarningRule(
      ControllerOwnedStreamValueDisposeRequiredRule(),
    );
    registry.registerWarningRule(
      ControllerStreamValueModelOwnershipForbiddenRule(),
    );
    registry.registerWarningRule(RoutePageMustLiveInRoutesFolderRule());
    registry.registerWarningRule(RoutePathParamRequiresResolverRouteRule());
    registry.registerWarningRule(RouteRequiredNonUrlArgsForbiddenRule());
    registry.registerWarningRule(
      ScreenControllerResolutionPatternRequiredRule(),
    );
    registry.registerWarningRule(
      ScreenDescendantWidgetControllerResolutionForbiddenRule(),
    );
    registry.registerWarningRule(UiRouteParamHydrationForbiddenRule());
    registry.registerWarningRule(MultiPublicClassFileWarningRule());
    registry.registerWarningRule(MultiWidgetFileWarningRule());
    registry.registerWarningRule(
      WidgetControllerSingletonRegistrationForbiddenRule(),
    );
    registry.registerWarningRule(TenantCanonicalDomainRequiredRule());
    registry.registerWarningRule(
      TimezoneServiceDirectDateTimeConversionForbiddenRule(),
    );
    registry.registerWarningRule(
      IntegrationAnonymousAuthIdentifiedLoginForbiddenRule(),
    );
    registry.registerWarningRule(
      LocationOriginCanonicalResolutionRequiredRule(),
    );
    registry.registerWarningRule(
      LocationOriginCanonicalStreamSubscriptionRequiredRule(),
    );
    registry.registerWarningRule(
      FlutterSentryUnreportedDebugPrintCatchForbiddenRule(),
    );
  }
}
