FROM evolvedbinary/elemental:${elemental.version}

# Copy Majlis dependencies XAR fiels to Elemental's autodeploy folder
COPY templating-${html-templating.xar.version}.xar /elemental/autodeploy/
COPY githubxq-${githubxq.xar.version}.xar /elemental/autodeploy/
COPY expath-crypto-module-${crypto.xar.version}.xar /elemental/autodeploy/
COPY exist-sparql-${sparql.xar.version}.xar /elemental/autodeploy/

# Copy Srophe XAR to Elemental's autodeploy folder
COPY ${package-final-name}.xar /elemental/autodeploy/

# Build-time metadata as defined at http://label-schema.org
# and used by autobuilder @hooks/build
LABEL org.label-schema.build-date=${maven.build.timestamp} \
      org.label-schema.description="${project.description}" \
      org.label-schema.name="${project.name}" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.url="${project.url}" \
      org.label-schema.vcs-ref=${build-commit-abbrev} \
      org.label-schema.vcs-url="${project.scm.url}" \
      org.label-schema.vendor="Winona Salesky" \
      org.opencontainers.image.source="${project.scm.url}"

EXPOSE 8080 8443
