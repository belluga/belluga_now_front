// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';

class AccountProfileCandidateGenericEndpointForbiddenRule extends DartLintRule {
  AccountProfileCandidateGenericEndpointForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.warning,
          name: 'account_profile_candidate_generic_endpoint_forbidden',
          problemMessage:
              'Account Profile candidate selection must not use the generic administrative listing endpoint.',
          correctionMessage:
              'Create a scoped candidate-picker session backed by fetchAccountProfileCandidatesPage and /account_profiles/candidates.',
        ),
      );

  static const _genericMethods = <String>{
    'fetchAccountProfiles',
    'fetchAccountProfilesPage',
    'encodeFetchAccountProfilesQuery',
  };

  static const _candidateOnlyArguments = <String>{
    'queryableOnly',
    'contactChannelsEnabledOnly',
    'contactMode',
    'excludeAccountProfileId',
  };

  static const _legacySessionMethods = <String>{
    'loadNestedProfileCandidates',
    'loadContactSourceCandidates',
    'searchNestedProfileCandidates',
    'searchContactSourceCandidates',
    'filterNestedProfileCandidatesByProfileType',
    'filterContactSourceCandidatesByProfileType',
    'loadNextNestedProfileCandidatesPage',
    'loadNextContactSourceCandidatesPage',
  };

  static const _candidateContextTokens = <String>{
    'candidate',
    'picker',
    'selection',
    'contactsource',
    'mirroredprofile',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isLibFilePath(path)) return;
    context.registry.addMethodInvocation((node) {
      final methodName = node.methodName.name;
      if (_legacySessionMethods.contains(methodName)) {
        reporter.atNode(node, code);
        return;
      }
      if (!_genericMethods.contains(methodName)) return;

      if (_isCandidateContext(node, path)) {
        reporter.atNode(node, code);
        return;
      }

      final hasCandidateOnlyArgument = node.argumentList.arguments.any(
        (argument) =>
            argument is NamedExpression &&
            _candidateOnlyArguments.contains(argument.name.label.name),
      );
      if (hasCandidateOnlyArgument) {
        reporter.atNode(node, code);
      }
    });

    context.registry.addMethodDeclaration((node) {
      if (_legacySessionMethods.contains(node.name.lexeme)) {
        reporter.atNode(node, code);
        return;
      }
      if (!_genericMethods.contains(node.name.lexeme)) return;

      if (_isCandidateContext(node, path)) {
        reporter.atNode(node, code);
        return;
      }

      final hasCandidateOnlyParameter =
          node.parameters?.parameters.any(
            (parameter) =>
                _candidateOnlyArguments.contains(parameter.name?.lexeme),
          ) ??
          false;
      if (hasCandidateOnlyParameter) {
        reporter.atNode(node, code);
      }
    });
  }

  bool _isCandidateContext(AstNode node, String path) {
    if (_containsCandidateContextToken(path)) {
      return true;
    }

    AstNode? ancestor = node.parent;
    while (ancestor != null) {
      final name = switch (ancestor) {
        MethodDeclaration() => ancestor.name.lexeme,
        ClassDeclaration() => ancestor.name.lexeme,
        _ => '',
      };
      if (_containsCandidateContextToken(name)) {
        return true;
      }
      ancestor = ancestor.parent;
    }
    return false;
  }

  bool _containsCandidateContextToken(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    return _candidateContextTokens.any(normalized.contains);
  }
}
