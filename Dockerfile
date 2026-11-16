# CRSF R environment for federal compute (Anvil, Expanse, Perlmutter, OSPool).
# Mirrors firebreather's R 4.5.1 package set (env/r-packages.txt, 440 CRAN packages).
# Built by GitHub Actions and published as ghcr.io/holoros/crsf-r:4.5.1
FROM rocker/geospatial:4.5.1

COPY r-packages.txt /tmp/r-packages.txt
RUN Rscript -e 'p <- readLines("/tmp/r-packages.txt"); \
      p <- setdiff(p, rownames(installed.packages())); \
      install.packages(p, Ncpus = 4); \
      miss <- setdiff(readLines("/tmp/r-packages.txt"), rownames(installed.packages())); \
      writeLines(miss, "/opt/r-packages-missing.txt"); \
      cat("missing:", length(miss), "\n")'

# Stan toolchain (cmdstanr from r-universe, CmdStan compiled into the image)
RUN Rscript -e 'install.packages("cmdstanr", repos = c("https://stan-dev.r-universe.dev", getOption("repos")))' \
 && Rscript -e 'cmdstanr::install_cmdstan(dir = "/opt/cmdstan", cores = 4)'
ENV CMDSTAN=/opt/cmdstan

# Lab packages not on CRAN. stLMM from GitHub; crownwidth and gydb are added
# as source tarballs in pkgs/ when their owners approve (not yet included).
RUN Rscript -e 'remotes::install_github("finleya/stLMM", upgrade = "never")'
COPY pkgs/ /tmp/pkgs/
RUN for f in /tmp/pkgs/*.tar.gz; do [ -e "$f" ] && R CMD INSTALL "$f"; done; true

LABEL org.opencontainers.image.source="https://github.com/holoros/crsf-r-env"
LABEL org.opencontainers.image.description="R 4.5.1 + geospatial + CRSF package set for HPC"
