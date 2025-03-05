# Void Linux Custom Package Repository Builder

This Docker setup allows you to build and maintain a custom repository of Void Linux packages. It keeps your repository completely separate from the main void-packages repository while leveraging the build system, and includes a caching mechanism to speed up builds - especially useful for time-consuming builds like the Linux kernel.

## Directory Structure

Your repository should have this structure:

```
dex-xbps-repo/
├── Dockerfile
├── docker-compose.yml
├── scripts/
│   ├── build-package.sh
│   ├── update-repo.sh
│   └── build-all.sh
├── binpkgs/       # Built packages will appear here
└── srcpkgs/       # Your package templates
    ├── package1/
    │   └── template
    ├── package2/
    │   └── template
    └── ...
```

## Setting Up

1. Create the directory structure and copy the provided files
2. Build the Docker image:

```bash
docker-compose build
```

## Using the Builder

### Build a Single Package

```bash
# Start the container
docker-compose run --rm void-builder

# Inside the container
build-package t2linux6.13
```

### Build All Packages

```bash
# Start the container
docker-compose run --rm void-builder

# Inside the container
build-all
```

### Update Repository Metadata

```bash
# Inside the container
update-repo
```

## Using Your Repository

After building your packages, the binpkgs directory will contain your packages and repository metadata. You can use this on a Void Linux system by adding it to your XBPS configuration:

```bash
echo 'repository=/path/to/dex-xbps-repo/binpkgs/x86_64-repodata' > /etc/xbps.d/10-custom-repo.conf
```

## Signing Packages

To sign your packages:

1. Place your private key in the repository root as `private.pem`
2. Run `update-repo` which will automatically detect and use the key

## Build Cache

This setup includes a persistent cache to speed up builds:

- Build artifacts are cached between container runs
- Compiler cache (ccache) is automatically enabled for kernel packages
- Source files are preserved to avoid repeated downloads

### Managing the Cache

You can use the `clean-cache` script to manage the cache:

```bash
# Clean cache for a specific package
clean-cache t2linux6.13

# Clean only the compiler cache
clean-cache ccache

# Clean the entire build cache (use with caution)
clean-cache all
```

## Notes

- Your custom packages are completely separate from the main void-packages repository
- Each build uses a fresh copy of your package template but preserves build artifacts
- The Docker container has access to the main Void Linux repositories for dependencies
- You can build packages for different architectures by passing the architecture to the build scripts
- For kernel builds, compiler cache (ccache) is automatically enabled for faster rebuilds
