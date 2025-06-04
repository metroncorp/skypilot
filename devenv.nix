{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/basics/
  env = {
    # SkyPilot development environment variables
    SKYPILOT_DEBUG = "1";
    SKYPILOT_DISABLE_USAGE_COLLECTION = "1";
    SKYPILOT_MINIMIZE_LOGGING = "0";
    GO111MODULE = "on";
    DOCKER_HOST = "unix:///var/folders/rr/x6r10g9545s_kxy6jmrfxb4m0000gn/T/podman/podman-machine-default-api.sock";
  };

  # https://devenv.sh/packages/
  packages = with pkgs; [
    # Essential tools
    git
    curl
    wget

    # Python and package management
    python310
    uv

    # Development tools
    pre-commit
    ruff  # Fast Python linter and formatter

    # System utilities that SkyPilot might need
    rsync
    openssh
    gnugrep
    findutils
    coreutils
    go
    rustup
    docker
    kubectl
    kind
    tilt
    k9s

    # Cloud CLI tools (optional, can be installed via uv/pip later)
    awscli2
  ];

  # https://devenv.sh/languages/
  languages.python = {
    enable = true;
    version = "3.10";
  };

  languages.go.enable = true;
  languages.rust.enable = true;

  # https://devenv.sh/scripts/
  scripts = {
    # Script to set up SkyPilot development environment
    setup-dev.exec = ''
      echo "🚀 Setting up SkyPilot development environment..."

      # Create virtual environment if it doesn't exist
      if [ ! -d ".venv" ]; then
        echo "🐍 Creating Python 3.10 virtual environment..."
        uv venv --python 3.10 .venv
      fi

      echo "🔄 Activating virtual environment..."
      source .venv/bin/activate

      # Install SkyPilot in editable mode with all dependencies
      echo "📦 Installing SkyPilot with all cloud providers..."
      uv pip install --prerelease=allow -e ".[all]"

      # Install development dependencies
      echo "🔧 Installing development dependencies..."
      uv pip install --prerelease=allow -r requirements-dev.txt

      # Install pre-commit hooks
      echo "🪝 Setting up pre-commit hooks..."
      pre-commit install

      # Verify pre-commit setup
      echo "✅ Verifying pre-commit configuration..."
      if [ -f ".pre-commit-config.yaml" ]; then
        echo "✅ Pre-commit config found: .pre-commit-config.yaml"
        echo "🔍 Pre-commit hooks configured:"
        pre-commit --version
      else
        echo "⚠️  No .pre-commit-config.yaml found"
      fi

      echo "✅ Development environment setup complete!"
      echo ""
      echo "💡 To activate the environment in future sessions:"
      echo "   source .venv/bin/activate"
      echo ""
      echo "🪝 Pre-commit is now active and will run on commits"
      echo "   • Run 'pre-commit-run' to test all hooks manually"
      echo "   • Run 'pre-commit-update' to update hook versions"
      echo ""
      echo "🧪 To run tests:"
      echo "  pytest tests/test_smoke.py::test_minimal"
      echo ""
      echo "🎯 To run a specific cloud test:"
      echo "  pytest tests/test_smoke.py --gcp"
      echo ""
      echo "📋 To check code formatting:"
      echo "  ./format.sh"
    '';

    # Activate the virtual environment
    activate.exec = ''
      if [ -d ".venv" ]; then
        echo "🔄 Activating Python virtual environment..."
        source .venv/bin/activate
        echo "✅ Virtual environment activated!"
        echo "🐍 Python: $(python --version)"
        echo "📦 Location: $(which python)"
      else
        echo "❌ Virtual environment not found. Run 'setup-dev' first."
      fi
    '';

    # Quick format script
    format.exec = ''
      echo "🎨 Formatting code..."
      ./format.sh
    '';

    # Ruff scripts
    ruff-check.exec = ''
      echo "🔍 Running ruff linter..."
      ruff check sky/ --fix
    '';

    ruff-format.exec = ''
      echo "🎨 Running ruff formatter..."
      ruff format sky/
    '';

    ruff-all.exec = ''
      echo "🚀 Running ruff check + format..."
      ruff check sky/ --fix
      ruff format sky/
    '';

    # Pre-commit scripts
    pre-commit-run.exec = ''
      echo "🪝 Running pre-commit on all files..."
      if [ -d ".venv" ]; then
        source .venv/bin/activate
      fi
      pre-commit run --all-files
    '';

    pre-commit-update.exec = ''
      echo "🔄 Updating pre-commit hooks..."
      if [ -d ".venv" ]; then
        source .venv/bin/activate
      fi
      pre-commit autoupdate
    '';

    # Quick test script that auto-activates venv
    test-minimal.exec = ''
      echo "🧪 Running minimal smoke test..."
      if [ -d ".venv" ]; then
        source .venv/bin/activate
      fi
      pytest tests/test_smoke.py::test_minimal
    '';

    # Status check script
    status.exec = ''
      echo "📊 SkyPilot Development Environment Status"
      echo "=========================================="
      echo "📍 Repository: $(pwd)"
      echo "🐍 System Python: $(python --version)"
      echo "📦 System Python location: $(which python)"
      echo "🔧 uv version: $(uv --version)"
      echo "🔧 git version: $(git --version)"
      echo ""

      # Check virtual environment
      if [ -d ".venv" ]; then
        echo "✅ Virtual environment: .venv (exists)"
        source .venv/bin/activate
        echo "🐍 Venv Python: $(python --version)"
        echo "📦 Venv location: $(which python)"

        # Check if SkyPilot is installed
        if python -c "import sky" 2>/dev/null; then
          echo "✅ SkyPilot: installed and importable"
          python -c "import sky; print(f'📦 SkyPilot version: {sky.__version__}')" 2>/dev/null || echo "📦 SkyPilot version: development"
        else
          echo "❌ SkyPilot: not installed in venv"
          echo "💡 Run 'setup-dev' to install it"
        fi

        # Check if dev dependencies are available
        if python -c "import pytest" 2>/dev/null; then
          echo "✅ Development dependencies: installed"
        else
          echo "❌ Development dependencies: not installed"
          echo "💡 Run 'setup-dev' to install them"
        fi
      else
        echo "❌ Virtual environment: not created"
        echo "💡 Run 'setup-dev' to create and set up"
      fi
    '';

    # Clean up installed packages
    clean.exec = ''
      echo "🧹 Cleaning up virtual environment..."
      if [ -d ".venv" ]; then
        rm -rf .venv
        echo "✅ Virtual environment removed."
      else
        echo "💡 No virtual environment found."
      fi
      echo "🚀 Run 'setup-dev' to recreate."
    '';
  };

  enterShell = ''
    echo "🌤️  Welcome to SkyPilot development environment!"
    echo "📍 Repository: $(pwd)"
    echo "🐍 System Python: $(python --version) ($(which python))"
    echo "📦 uv: $(uv --version)"
    echo ""

    # Check if virtual environment exists and SkyPilot is installed
    if [ -d ".venv" ]; then
      echo "✅ Virtual environment found: .venv"
      source .venv/bin/activate
      if python -c "import sky" 2>/dev/null; then
        echo "✅ SkyPilot is installed and ready to use!"
        echo "🔄 Virtual environment auto-activated"
      else
        echo "⚠️  Virtual environment exists but SkyPilot not installed"
        echo "🚀 Run 'setup-dev' to install SkyPilot and dependencies"
      fi
    else
      echo "💡 No virtual environment found."
      echo "🚀 Run 'setup-dev' to create and set up the development environment"
    fi

    echo ""
    echo "Available commands:"
    echo "  🚀 setup-dev     - Create venv and install SkyPilot + dev dependencies"
    echo "  🔄 activate      - Activate the Python virtual environment"
    echo "  🎨 format        - Format code with ./format.sh"
    echo "  🔍 ruff-check    - Run ruff linter with auto-fix"
    echo "  🎨 ruff-format   - Run ruff formatter"
    echo "  🚀 ruff-all      - Run ruff check + format"
    echo "  🪝 pre-commit-run - Run pre-commit hooks on all files"
    echo "  🔄 pre-commit-update - Update pre-commit hooks"
    echo "  🧪 test-minimal  - Run minimal smoke test"
    echo "  📊 status        - Show detailed environment status"
    echo "  🧹 clean         - Remove virtual environment"
    echo ""
    echo "📚 See all available commands with: devenv info"
  '';

  # https://devenv.sh/tests/
  enterTest = ''
    echo "🧪 Running development environment tests..."
    python --version
    uv --version
    git --version

    if python -c "import sky" 2>/dev/null; then
      echo "✅ SkyPilot import test: passed"
    fi

    echo "✅ All tools available!"
  '';

  # See full reference at https://devenv.sh/reference/options/
}
