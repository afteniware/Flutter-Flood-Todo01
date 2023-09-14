import 'dart:async';

import 'package:jlogical_utils_core/jlogical_utils_core.dart';

Future<CorePondContext> getCorePondContext({
  EnvironmentConfig? environmentConfig,
  List<CorePondComponent> Function(CorePondContext context)? additionalCoreComponents,
  List<RepositoryImplementation> repositoryImplementations = const [],
  List<AuthServiceImplementation> authServiceImplementations = const [],
  FutureOr Function(CorePondContext context, String userId)? onAfterLogin,
  FutureOr Function(CorePondContext context, String userId)? onBeforeLogout,
}) async {
  environmentConfig ??= EnvironmentConfig.static.memory();

  final corePondContext = CorePondContext();

  await corePondContext.register(TypeCoreComponent());
  await corePondContext.register(EnvironmentConfigCoreComponent(environmentConfig: environmentConfig));

  for (final coreComponent in additionalCoreComponents?.call(corePondContext) ?? []) {
    await corePondContext.register(coreComponent);
  }

  await corePondContext.register(AuthCoreComponent(
    authService: AuthService.static.adapting().withListener(
          onAfterLogin: onAfterLogin == null ? null : (userId) => onAfterLogin(corePondContext, userId),
          onBeforeLogout: onBeforeLogout == null ? null : (userId) => onBeforeLogout(corePondContext, userId),
        ),
    authServiceImplementations: authServiceImplementations,
  ));
  await corePondContext.register(DropCoreComponent(
    repositoryImplementations: repositoryImplementations,
    authenticatedUserIdX:
        corePondContext.locate<AuthCoreComponent>().userIdX.mapWithValue((maybeUserIdX) => maybeUserIdX.getOrNull()),
  ));
  await corePondContext.register(LogCoreComponent.console());
  await corePondContext.register(
      ActionCoreComponent(actionWrapper: <P, R>(Action<P, R> action) => action.log(context: corePondContext)));
  await corePondContext.register(PortDropCoreComponent());

  // TODO Register repositories here.

  return corePondContext;
}

Future<CorePondContext> getTestingCorePondContext() async {
  final corePondContext = await getCorePondContext(
    environmentConfig: EnvironmentConfig.static.testing(),
    repositoryImplementations: [],
  );

  await corePondContext.locate<AuthCoreComponent>().signup('asdf@asdf.com', 'mypassword');

  return corePondContext;
}
