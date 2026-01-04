# Lambda Layers

This directory contains Lambda Layers for external dependencies.

## ✨ Automated Installation

**No manual steps required!** Terraform automatically installs dependencies when you run `terraform apply`.

The `null_resource.install_pypdf_dependencies` in Terraform:
- Detects changes to `requirements.txt`
- Automatically runs `pip install` before creating the layer
- Ensures dependencies are always up-to-date

## What Gets Committed

- ✅ `requirements.txt` - Dependency specifications
- ✅ `README.md` - Documentation
- ❌ `python/*` - Installed packages (gitignored)

## How It Works

1. Clone the repository
2. Run `terraform apply`
3. Terraform automatically:
   - Installs dependencies from `requirements.txt`
   - Creates the layer zip file
   - Deploys to AWS

**That's it!** No manual pip install needed.
