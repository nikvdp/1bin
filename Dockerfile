FROM ubuntu:22.04
# Install necessary tools
RUN apt-get update && apt-get install -y curl bash

# Set environment variables
RUN PLATFORM=$(uname -s) \
    && ARCH=$(uname -m) \
    && MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/download/24.3.0-0/Mambaforge-24.3.0-0-${PLATFORM}-${ARCH}.sh" \
    && echo '>>> '$MINIFORGE_URL \
    && curl -L "$MINIFORGE_URL" -o /tmp/miniconda.sh
RUN bash /tmp/miniconda.sh -b -p /opt/miniconda3 
RUN rm /tmp/miniconda.sh

# Create .condarc file
RUN echo '{ "always_yes": true, "channels": [ "conda-forge", "defaults" ] }' > /root/.condarc

# Ensure conda is on the PATH
ENV PATH="/opt/miniconda3/bin:$PATH"

RUN conda install mamba

RUN mamba update conda

RUN mamba install conda-build conda-verify

# RUN conda install conda-build conda-verify

