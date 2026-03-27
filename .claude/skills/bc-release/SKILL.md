---
name: bc-release
description: Create a new BigCommerce patched release of grpc. Use when upgrading to a new upstream grpc version, creating BC release branches/tags, or managing the BC fork.
---

# BC gRPC Release Management

This skill handles creating and managing BigCommerce-patched releases of grpc/grpc.

## Remotes

- `origin` = `grpc/grpc` (upstream)
- `bc` = `bigcommerce/grpc` (BC fork)

## Arguments

`$ARGUMENTS` should be the upstream version to target (e.g., `1.81.0`, `v1.81.x`).

## BC Patch

All BC releases apply a single patch to `src/compiler/php_generator.cc` that adds three PHP codegen customizations:

1. **`getExpectedResponseMessages()`** — maps method names to their response message types
2. **`getServiceName()`** — returns the fully qualified gRPC service name

The patch also includes `.github/workflows/release-php-plugin.yaml` which builds and attaches `grpc_php_plugin` binaries (linux-amd64, darwin-arm64) to the release automatically.

## Steps

### 1. Sync bc/master with upstream

```bash
git fetch origin && git fetch bc
git push bc origin/master:refs/heads/master --force
```

### 2. Push upstream release tags to bc

This is required so the compare link (`vX.YY.0...vX.YY.0-bc`) resolves on the BC fork.

```bash
# List all tags for the version
git tag -l 'vX.YY.*'
# Push ALL upstream tags for this release to bc
git push bc vX.YY.0 vX.YY.0-pre1  # include all tags from the list above
```

**Do not skip this step.** If the upstream tag is missing from bc, the release compare link and GitHub diff will be broken.

### 3. Create the release branch

```bash
git checkout -b X.YY.x-bc origin/vX.YY.x
```

### 4. Apply the BC patch

Read the current state of `src/compiler/php_generator.cc` on the new branch. Then apply these changes:

**In `PrintService()` function:**
- After `out->Indent(); out->Indent();`, before `if (!is_server)`, add:

```cpp
out->Print("public function getExpectedResponseMessages() {\n");
out->Indent();
out->Print("return [\n");
out->Indent();
map<std::string, std::string> response_vars;
for (int i = 0; i < service->method_count(); i++) {
  const Descriptor* output_type = service->method(i)->output_type();
  response_vars["method_name"] = grpc_generator::LowercaseFirstLetter(std::string(service->method(i)->name()));
  response_vars["output_type_id"] = MessageIdentifierName(GeneratedClassName(output_type), output_type->file());
  out->Print(response_vars, "'$method_name$' => '\\$output_type_id$',\n");
}
out->Outdent();
out->Print("];\n");
out->Outdent();
out->Print("}\n\n");

// getServiceName() -> string - The name of the gRPC service
map<std::string, std::string> service_vars;
service_vars["service_name"] = service->full_name();
out->Print("public function getServiceName() {\n");
out->Indent();
out->Print(service_vars, "return '$service_name$';\n");
out->Outdent();
out->Print("}\n\n");
```

**Also include the release workflow:**
- Copy `.github/workflows/release-php-plugin.yaml` from `bc/master` or the previous `-bc` branch.

### 5. Commit, tag, and push

```bash
git add src/compiler/php_generator.cc .github/workflows/release-php-plugin.yaml
git commit -m "Add BC PHP codegen customizations and release workflow"
git tag vX.YY.0-bc X.YY.x-bc
git push bc X.YY.x-bc
git push bc vX.YY.0-bc
```

### 6. Create the GitHub release

```bash
gh release create vX.YY.0-bc --repo bigcommerce/grpc \
  --title "vX.YY.0-bc" \
  --notes "gRPC vX.YY.0 with BigCommerce PHP codegen customizations.

Based on upstream [vX.YY.0](https://github.com/grpc/grpc/releases/tag/vX.YY.0). See [diff](https://github.com/bigcommerce/grpc/compare/vX.YY.0...vX.YY.0-bc)."
```

The `release-php-plugin.yaml` workflow will automatically build and attach `grpc_php_plugin` binaries.

### 7. Verify

- Compare link shows only the BC patch: `https://github.com/bigcommerce/grpc/compare/vX.YY.0...vX.YY.0-bc`
- Release workflow builds and attaches binaries: check GitHub Actions
- Release has `grpc_php_plugin-linux-amd64.zip` and `grpc_php_plugin-darwin-arm64.zip` assets

## Important Notes

- The patch modifies ONLY `src/compiler/php_generator.cc` — if upstream changes this file significantly, the patch may need manual adaptation (watch for type changes like `grpc::string` → `std::string`).
- Always read the current file before patching — don't blindly apply line numbers from previous versions.
- The release workflow lives on `bc/master`. If bc/master is synced (force-pushed) from upstream, the workflow file will be lost and needs to be re-added.
