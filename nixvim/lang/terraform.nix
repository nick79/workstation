{ ... }:

# Terraform: terraform-ls from the editor; the terraform CLI (unfree) and
# tflint come from the project shell. terraform-ls formats with that CLI
# (`terraform fmt`), and .tf files format on save by default (formatting.nix).
{
  lsp.servers = {
    terraformls.enable = true;

    # Only where the project configures tflint, and with its binary.
    tflint = {
      enable = true;
      package = null;
      config = {
        root_markers = [ ".tflint.hcl" ];
        workspace_required = true;
      };
    };
  };
}
