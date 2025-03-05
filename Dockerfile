FROM ghcr.io/void-linux/void-glibc-full:20250227R1

# Install required packages
RUN mkdir -p /etc/xbps.d && \
	cp /usr/share/xbps.d/*-repository-*.conf /etc/xbps.d/ && \
	sed -i 's|repo-default|repo-ci|g' /etc/xbps.d/*-repository-*.conf && \
	xbps-install -Syu xbps && \
	xbps-install -yu && \
	xbps-install -y sudo bash curl git xtools clang18 vim

# Create builder user
RUN useradd -G xbuilder -m builder && \
	echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Setup directory structure
RUN mkdir -p /void-packages /custom-repo
WORKDIR /void-packages

# Clone void-packages repo
RUN git clone --depth=1 https://github.com/void-linux/void-packages.git . && \
	mkdir -p /void-packages/hostdir && \
	chown -R builder:builder /void-packages /custom-repo

# We'll initialize void-packages in the entrypoint script to use cached data
COPY --chown=builder:builder scripts/entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

# Add build scripts
COPY --chown=builder:builder scripts/build-package.sh /usr/local/bin/build-package
COPY --chown=builder:builder scripts/update-repo.sh /usr/local/bin/update-repo
COPY --chown=builder:builder scripts/build-all.sh /usr/local/bin/build-all
COPY --chown=builder:builder scripts/clean-cache.sh /usr/local/bin/clean-cache
COPY --chown=builder:builder scripts/update-checksum.sh /usr/local/bin/update-checksum

RUN chmod +x /usr/local/bin/build-package /usr/local/bin/update-repo \
	/usr/local/bin/build-all /usr/local/bin/clean-cache

# Set default working directory to the custom repo
WORKDIR /custom-repo

# Switch to builder user by default
USER builder

# Use our entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD ["/bin/bash"]
