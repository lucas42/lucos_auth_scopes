# Publish the scope vocabulary as a minimal image so consumers can pull it
# at build-time with:
#   COPY --from=lucas42/lucos_auth_scopes:<version> /scopes.yaml ./scopes.yaml
#
# scratch: no base layer — just the YAML file. This is a data-only image,
# not a runnable service.
FROM scratch
ARG VERSION
ENV VERSION=$VERSION
COPY scopes.yaml /scopes.yaml
